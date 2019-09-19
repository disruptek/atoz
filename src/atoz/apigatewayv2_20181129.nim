
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApi_601025 = ref object of OpenApiRestCall_600426
proc url_CreateApi_601027(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApi_601026(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601028 = header.getOrDefault("X-Amz-Date")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Date", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Security-Token")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Security-Token", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Content-Sha256", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Algorithm")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Algorithm", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Signature")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Signature", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-SignedHeaders", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Credential")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Credential", valid_601034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_CreateApi_601025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"))
  result = hook(call_601036, url, valid)

proc call*(call_601037: Call_CreateApi_601025; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_601038 = newJObject()
  if body != nil:
    body_601038 = body
  result = call_601037.call(nil, nil, nil, nil, body_601038)

var createApi* = Call_CreateApi_601025(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_601026,
                                    base: "/", url: url_CreateApi_601027,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_600768 = ref object of OpenApiRestCall_600426
proc url_GetApis_600770(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApis_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600882 = query.getOrDefault("maxResults")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "maxResults", valid_600882
  var valid_600883 = query.getOrDefault("nextToken")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "nextToken", valid_600883
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Content-Sha256", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Algorithm")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Algorithm", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Signature")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Signature", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-SignedHeaders", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Credential")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Credential", valid_600890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_GetApis_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_GetApis_600768; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var query_600985 = newJObject()
  add(query_600985, "maxResults", newJString(maxResults))
  add(query_600985, "nextToken", newJString(nextToken))
  result = call_600984.call(nil, query_600985, nil, nil, nil)

var getApis* = Call_GetApis_600768(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_600769,
                                base: "/", url: url_GetApis_600770,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_601070 = ref object of OpenApiRestCall_600426
proc url_CreateApiMapping_601072(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateApiMapping_601071(path: JsonNode; query: JsonNode;
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
  var valid_601073 = path.getOrDefault("domainName")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "domainName", valid_601073
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
  var valid_601074 = header.getOrDefault("X-Amz-Date")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Date", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Security-Token")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Security-Token", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Content-Sha256", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Algorithm")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Algorithm", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Signature")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Signature", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-SignedHeaders", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Credential")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Credential", valid_601080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601082: Call_CreateApiMapping_601070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_601082.validator(path, query, header, formData, body)
  let scheme = call_601082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601082.url(scheme.get, call_601082.host, call_601082.base,
                         call_601082.route, valid.getOrDefault("path"))
  result = hook(call_601082, url, valid)

proc call*(call_601083: Call_CreateApiMapping_601070; domainName: string;
          body: JsonNode): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_601084 = newJObject()
  var body_601085 = newJObject()
  add(path_601084, "domainName", newJString(domainName))
  if body != nil:
    body_601085 = body
  result = call_601083.call(path_601084, nil, nil, nil, body_601085)

var createApiMapping* = Call_CreateApiMapping_601070(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_601071, base: "/",
    url: url_CreateApiMapping_601072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_601039 = ref object of OpenApiRestCall_600426
proc url_GetApiMappings_601041(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApiMappings_601040(path: JsonNode; query: JsonNode;
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
  var valid_601056 = path.getOrDefault("domainName")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = nil)
  if valid_601056 != nil:
    section.add "domainName", valid_601056
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601057 = query.getOrDefault("maxResults")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "maxResults", valid_601057
  var valid_601058 = query.getOrDefault("nextToken")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "nextToken", valid_601058
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
  var valid_601059 = header.getOrDefault("X-Amz-Date")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Date", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Security-Token")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Security-Token", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Content-Sha256", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Algorithm")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Algorithm", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Signature")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Signature", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-SignedHeaders", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Credential")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Credential", valid_601065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_GetApiMappings_601039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mappings.
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"))
  result = hook(call_601066, url, valid)

proc call*(call_601067: Call_GetApiMappings_601039; domainName: string;
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
  var path_601068 = newJObject()
  var query_601069 = newJObject()
  add(query_601069, "maxResults", newJString(maxResults))
  add(query_601069, "nextToken", newJString(nextToken))
  add(path_601068, "domainName", newJString(domainName))
  result = call_601067.call(path_601068, query_601069, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_601039(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_601040, base: "/", url: url_GetApiMappings_601041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_601103 = ref object of OpenApiRestCall_600426
proc url_CreateAuthorizer_601105(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateAuthorizer_601104(path: JsonNode; query: JsonNode;
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
  var valid_601106 = path.getOrDefault("apiId")
  valid_601106 = validateParameter(valid_601106, JString, required = true,
                                 default = nil)
  if valid_601106 != nil:
    section.add "apiId", valid_601106
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
  var valid_601107 = header.getOrDefault("X-Amz-Date")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Date", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Security-Token")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Security-Token", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Content-Sha256", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Algorithm")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Algorithm", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Signature")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Signature", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-SignedHeaders", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Credential")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Credential", valid_601113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_CreateAuthorizer_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_CreateAuthorizer_601103; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601117 = newJObject()
  var body_601118 = newJObject()
  add(path_601117, "apiId", newJString(apiId))
  if body != nil:
    body_601118 = body
  result = call_601116.call(path_601117, nil, nil, nil, body_601118)

var createAuthorizer* = Call_CreateAuthorizer_601103(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_601104,
    base: "/", url: url_CreateAuthorizer_601105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_601086 = ref object of OpenApiRestCall_600426
proc url_GetAuthorizers_601088(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAuthorizers_601087(path: JsonNode; query: JsonNode;
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
  var valid_601089 = path.getOrDefault("apiId")
  valid_601089 = validateParameter(valid_601089, JString, required = true,
                                 default = nil)
  if valid_601089 != nil:
    section.add "apiId", valid_601089
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601090 = query.getOrDefault("maxResults")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "maxResults", valid_601090
  var valid_601091 = query.getOrDefault("nextToken")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "nextToken", valid_601091
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
  var valid_601092 = header.getOrDefault("X-Amz-Date")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Date", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Security-Token")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Security-Token", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601099: Call_GetAuthorizers_601086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_601099.validator(path, query, header, formData, body)
  let scheme = call_601099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601099.url(scheme.get, call_601099.host, call_601099.base,
                         call_601099.route, valid.getOrDefault("path"))
  result = hook(call_601099, url, valid)

proc call*(call_601100: Call_GetAuthorizers_601086; apiId: string;
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
  var path_601101 = newJObject()
  var query_601102 = newJObject()
  add(path_601101, "apiId", newJString(apiId))
  add(query_601102, "maxResults", newJString(maxResults))
  add(query_601102, "nextToken", newJString(nextToken))
  result = call_601100.call(path_601101, query_601102, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_601086(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_601087,
    base: "/", url: url_GetAuthorizers_601088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_601136 = ref object of OpenApiRestCall_600426
proc url_CreateDeployment_601138(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDeployment_601137(path: JsonNode; query: JsonNode;
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
  var valid_601139 = path.getOrDefault("apiId")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = nil)
  if valid_601139 != nil:
    section.add "apiId", valid_601139
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
  var valid_601140 = header.getOrDefault("X-Amz-Date")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Date", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Security-Token")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Security-Token", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Content-Sha256", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Algorithm")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Algorithm", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Signature")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Signature", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-SignedHeaders", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Credential")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Credential", valid_601146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601148: Call_CreateDeployment_601136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_601148.validator(path, query, header, formData, body)
  let scheme = call_601148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601148.url(scheme.get, call_601148.host, call_601148.base,
                         call_601148.route, valid.getOrDefault("path"))
  result = hook(call_601148, url, valid)

proc call*(call_601149: Call_CreateDeployment_601136; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601150 = newJObject()
  var body_601151 = newJObject()
  add(path_601150, "apiId", newJString(apiId))
  if body != nil:
    body_601151 = body
  result = call_601149.call(path_601150, nil, nil, nil, body_601151)

var createDeployment* = Call_CreateDeployment_601136(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_601137,
    base: "/", url: url_CreateDeployment_601138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_601119 = ref object of OpenApiRestCall_600426
proc url_GetDeployments_601121(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeployments_601120(path: JsonNode; query: JsonNode;
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
  var valid_601122 = path.getOrDefault("apiId")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = nil)
  if valid_601122 != nil:
    section.add "apiId", valid_601122
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601123 = query.getOrDefault("maxResults")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "maxResults", valid_601123
  var valid_601124 = query.getOrDefault("nextToken")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "nextToken", valid_601124
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
  var valid_601125 = header.getOrDefault("X-Amz-Date")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Date", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Security-Token")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Security-Token", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Content-Sha256", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Algorithm")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Algorithm", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Signature")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Signature", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-SignedHeaders", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Credential")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Credential", valid_601131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_GetDeployments_601119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_GetDeployments_601119; apiId: string;
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
  var path_601134 = newJObject()
  var query_601135 = newJObject()
  add(path_601134, "apiId", newJString(apiId))
  add(query_601135, "maxResults", newJString(maxResults))
  add(query_601135, "nextToken", newJString(nextToken))
  result = call_601133.call(path_601134, query_601135, nil, nil, nil)

var getDeployments* = Call_GetDeployments_601119(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_601120,
    base: "/", url: url_GetDeployments_601121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_601167 = ref object of OpenApiRestCall_600426
proc url_CreateDomainName_601169(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDomainName_601168(path: JsonNode; query: JsonNode;
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
  var valid_601170 = header.getOrDefault("X-Amz-Date")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Date", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Security-Token")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Security-Token", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Content-Sha256", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Algorithm")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Algorithm", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Signature")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Signature", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-SignedHeaders", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Credential")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Credential", valid_601176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601178: Call_CreateDomainName_601167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_601178.validator(path, query, header, formData, body)
  let scheme = call_601178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601178.url(scheme.get, call_601178.host, call_601178.base,
                         call_601178.route, valid.getOrDefault("path"))
  result = hook(call_601178, url, valid)

proc call*(call_601179: Call_CreateDomainName_601167; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_601180 = newJObject()
  if body != nil:
    body_601180 = body
  result = call_601179.call(nil, nil, nil, nil, body_601180)

var createDomainName* = Call_CreateDomainName_601167(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_601168,
    base: "/", url: url_CreateDomainName_601169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_601152 = ref object of OpenApiRestCall_600426
proc url_GetDomainNames_601154(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainNames_601153(path: JsonNode; query: JsonNode;
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
  var valid_601155 = query.getOrDefault("maxResults")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "maxResults", valid_601155
  var valid_601156 = query.getOrDefault("nextToken")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "nextToken", valid_601156
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
  var valid_601157 = header.getOrDefault("X-Amz-Date")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Date", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Security-Token")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Security-Token", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Content-Sha256", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Algorithm")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Algorithm", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Signature")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Signature", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-SignedHeaders", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Credential")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Credential", valid_601163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601164: Call_GetDomainNames_601152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_601164.validator(path, query, header, formData, body)
  let scheme = call_601164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601164.url(scheme.get, call_601164.host, call_601164.base,
                         call_601164.route, valid.getOrDefault("path"))
  result = hook(call_601164, url, valid)

proc call*(call_601165: Call_GetDomainNames_601152; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var query_601166 = newJObject()
  add(query_601166, "maxResults", newJString(maxResults))
  add(query_601166, "nextToken", newJString(nextToken))
  result = call_601165.call(nil, query_601166, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_601152(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_601153, base: "/",
    url: url_GetDomainNames_601154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_601198 = ref object of OpenApiRestCall_600426
proc url_CreateIntegration_601200(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateIntegration_601199(path: JsonNode; query: JsonNode;
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
  var valid_601201 = path.getOrDefault("apiId")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "apiId", valid_601201
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
  var valid_601202 = header.getOrDefault("X-Amz-Date")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Date", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Security-Token")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Security-Token", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Content-Sha256", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Algorithm")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Algorithm", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Signature")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Signature", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-SignedHeaders", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Credential")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Credential", valid_601208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601210: Call_CreateIntegration_601198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_601210.validator(path, query, header, formData, body)
  let scheme = call_601210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601210.url(scheme.get, call_601210.host, call_601210.base,
                         call_601210.route, valid.getOrDefault("path"))
  result = hook(call_601210, url, valid)

proc call*(call_601211: Call_CreateIntegration_601198; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601212 = newJObject()
  var body_601213 = newJObject()
  add(path_601212, "apiId", newJString(apiId))
  if body != nil:
    body_601213 = body
  result = call_601211.call(path_601212, nil, nil, nil, body_601213)

var createIntegration* = Call_CreateIntegration_601198(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_601199,
    base: "/", url: url_CreateIntegration_601200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_601181 = ref object of OpenApiRestCall_600426
proc url_GetIntegrations_601183(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIntegrations_601182(path: JsonNode; query: JsonNode;
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
  var valid_601184 = path.getOrDefault("apiId")
  valid_601184 = validateParameter(valid_601184, JString, required = true,
                                 default = nil)
  if valid_601184 != nil:
    section.add "apiId", valid_601184
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601185 = query.getOrDefault("maxResults")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "maxResults", valid_601185
  var valid_601186 = query.getOrDefault("nextToken")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "nextToken", valid_601186
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
  var valid_601187 = header.getOrDefault("X-Amz-Date")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Date", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Security-Token")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Security-Token", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Content-Sha256", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Algorithm")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Algorithm", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Signature")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Signature", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-SignedHeaders", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Credential")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Credential", valid_601193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601194: Call_GetIntegrations_601181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_601194.validator(path, query, header, formData, body)
  let scheme = call_601194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601194.url(scheme.get, call_601194.host, call_601194.base,
                         call_601194.route, valid.getOrDefault("path"))
  result = hook(call_601194, url, valid)

proc call*(call_601195: Call_GetIntegrations_601181; apiId: string;
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
  var path_601196 = newJObject()
  var query_601197 = newJObject()
  add(path_601196, "apiId", newJString(apiId))
  add(query_601197, "maxResults", newJString(maxResults))
  add(query_601197, "nextToken", newJString(nextToken))
  result = call_601195.call(path_601196, query_601197, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_601181(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_601182,
    base: "/", url: url_GetIntegrations_601183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_601232 = ref object of OpenApiRestCall_600426
proc url_CreateIntegrationResponse_601234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateIntegrationResponse_601233(path: JsonNode; query: JsonNode;
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
  var valid_601235 = path.getOrDefault("apiId")
  valid_601235 = validateParameter(valid_601235, JString, required = true,
                                 default = nil)
  if valid_601235 != nil:
    section.add "apiId", valid_601235
  var valid_601236 = path.getOrDefault("integrationId")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = nil)
  if valid_601236 != nil:
    section.add "integrationId", valid_601236
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
  var valid_601237 = header.getOrDefault("X-Amz-Date")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Date", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Security-Token")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Security-Token", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Content-Sha256", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Algorithm")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Algorithm", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Signature")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Signature", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-SignedHeaders", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Credential")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Credential", valid_601243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601245: Call_CreateIntegrationResponse_601232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_601245.validator(path, query, header, formData, body)
  let scheme = call_601245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601245.url(scheme.get, call_601245.host, call_601245.base,
                         call_601245.route, valid.getOrDefault("path"))
  result = hook(call_601245, url, valid)

proc call*(call_601246: Call_CreateIntegrationResponse_601232; apiId: string;
          body: JsonNode; integrationId: string): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_601247 = newJObject()
  var body_601248 = newJObject()
  add(path_601247, "apiId", newJString(apiId))
  if body != nil:
    body_601248 = body
  add(path_601247, "integrationId", newJString(integrationId))
  result = call_601246.call(path_601247, nil, nil, nil, body_601248)

var createIntegrationResponse* = Call_CreateIntegrationResponse_601232(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_601233, base: "/",
    url: url_CreateIntegrationResponse_601234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_601214 = ref object of OpenApiRestCall_600426
proc url_GetIntegrationResponses_601216(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIntegrationResponses_601215(path: JsonNode; query: JsonNode;
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
  var valid_601217 = path.getOrDefault("apiId")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = nil)
  if valid_601217 != nil:
    section.add "apiId", valid_601217
  var valid_601218 = path.getOrDefault("integrationId")
  valid_601218 = validateParameter(valid_601218, JString, required = true,
                                 default = nil)
  if valid_601218 != nil:
    section.add "integrationId", valid_601218
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601219 = query.getOrDefault("maxResults")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "maxResults", valid_601219
  var valid_601220 = query.getOrDefault("nextToken")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "nextToken", valid_601220
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
  var valid_601221 = header.getOrDefault("X-Amz-Date")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Date", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Security-Token")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Security-Token", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601228: Call_GetIntegrationResponses_601214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_601228.validator(path, query, header, formData, body)
  let scheme = call_601228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601228.url(scheme.get, call_601228.host, call_601228.base,
                         call_601228.route, valid.getOrDefault("path"))
  result = hook(call_601228, url, valid)

proc call*(call_601229: Call_GetIntegrationResponses_601214; apiId: string;
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
  var path_601230 = newJObject()
  var query_601231 = newJObject()
  add(path_601230, "apiId", newJString(apiId))
  add(query_601231, "maxResults", newJString(maxResults))
  add(query_601231, "nextToken", newJString(nextToken))
  add(path_601230, "integrationId", newJString(integrationId))
  result = call_601229.call(path_601230, query_601231, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_601214(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_601215, base: "/",
    url: url_GetIntegrationResponses_601216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_601266 = ref object of OpenApiRestCall_600426
proc url_CreateModel_601268(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateModel_601267(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601269 = path.getOrDefault("apiId")
  valid_601269 = validateParameter(valid_601269, JString, required = true,
                                 default = nil)
  if valid_601269 != nil:
    section.add "apiId", valid_601269
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
  var valid_601270 = header.getOrDefault("X-Amz-Date")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Date", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Security-Token")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Security-Token", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Content-Sha256", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Algorithm")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Algorithm", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Signature")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Signature", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-SignedHeaders", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Credential")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Credential", valid_601276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601278: Call_CreateModel_601266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_601278.validator(path, query, header, formData, body)
  let scheme = call_601278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601278.url(scheme.get, call_601278.host, call_601278.base,
                         call_601278.route, valid.getOrDefault("path"))
  result = hook(call_601278, url, valid)

proc call*(call_601279: Call_CreateModel_601266; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601280 = newJObject()
  var body_601281 = newJObject()
  add(path_601280, "apiId", newJString(apiId))
  if body != nil:
    body_601281 = body
  result = call_601279.call(path_601280, nil, nil, nil, body_601281)

var createModel* = Call_CreateModel_601266(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_601267,
                                        base: "/", url: url_CreateModel_601268,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_601249 = ref object of OpenApiRestCall_600426
proc url_GetModels_601251(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetModels_601250(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601252 = path.getOrDefault("apiId")
  valid_601252 = validateParameter(valid_601252, JString, required = true,
                                 default = nil)
  if valid_601252 != nil:
    section.add "apiId", valid_601252
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601253 = query.getOrDefault("maxResults")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "maxResults", valid_601253
  var valid_601254 = query.getOrDefault("nextToken")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "nextToken", valid_601254
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
  var valid_601255 = header.getOrDefault("X-Amz-Date")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Date", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Security-Token")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Security-Token", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Content-Sha256", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Algorithm")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Algorithm", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Signature")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Signature", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-SignedHeaders", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Credential")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Credential", valid_601261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601262: Call_GetModels_601249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_601262.validator(path, query, header, formData, body)
  let scheme = call_601262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601262.url(scheme.get, call_601262.host, call_601262.base,
                         call_601262.route, valid.getOrDefault("path"))
  result = hook(call_601262, url, valid)

proc call*(call_601263: Call_GetModels_601249; apiId: string;
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
  var path_601264 = newJObject()
  var query_601265 = newJObject()
  add(path_601264, "apiId", newJString(apiId))
  add(query_601265, "maxResults", newJString(maxResults))
  add(query_601265, "nextToken", newJString(nextToken))
  result = call_601263.call(path_601264, query_601265, nil, nil, nil)

var getModels* = Call_GetModels_601249(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_601250,
                                    base: "/", url: url_GetModels_601251,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_601299 = ref object of OpenApiRestCall_600426
proc url_CreateRoute_601301(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateRoute_601300(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601302 = path.getOrDefault("apiId")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = nil)
  if valid_601302 != nil:
    section.add "apiId", valid_601302
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
  var valid_601303 = header.getOrDefault("X-Amz-Date")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Date", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Security-Token")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Security-Token", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Content-Sha256", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Algorithm")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Algorithm", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Signature")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Signature", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-SignedHeaders", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Credential")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Credential", valid_601309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601311: Call_CreateRoute_601299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_601311.validator(path, query, header, formData, body)
  let scheme = call_601311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601311.url(scheme.get, call_601311.host, call_601311.base,
                         call_601311.route, valid.getOrDefault("path"))
  result = hook(call_601311, url, valid)

proc call*(call_601312: Call_CreateRoute_601299; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601313 = newJObject()
  var body_601314 = newJObject()
  add(path_601313, "apiId", newJString(apiId))
  if body != nil:
    body_601314 = body
  result = call_601312.call(path_601313, nil, nil, nil, body_601314)

var createRoute* = Call_CreateRoute_601299(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_601300,
                                        base: "/", url: url_CreateRoute_601301,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_601282 = ref object of OpenApiRestCall_600426
proc url_GetRoutes_601284(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRoutes_601283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601285 = path.getOrDefault("apiId")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = nil)
  if valid_601285 != nil:
    section.add "apiId", valid_601285
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601286 = query.getOrDefault("maxResults")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "maxResults", valid_601286
  var valid_601287 = query.getOrDefault("nextToken")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "nextToken", valid_601287
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
  var valid_601288 = header.getOrDefault("X-Amz-Date")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Date", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Security-Token")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Security-Token", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Content-Sha256", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Algorithm")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Algorithm", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Signature")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Signature", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-SignedHeaders", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Credential")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Credential", valid_601294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_GetRoutes_601282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"))
  result = hook(call_601295, url, valid)

proc call*(call_601296: Call_GetRoutes_601282; apiId: string;
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
  var path_601297 = newJObject()
  var query_601298 = newJObject()
  add(path_601297, "apiId", newJString(apiId))
  add(query_601298, "maxResults", newJString(maxResults))
  add(query_601298, "nextToken", newJString(nextToken))
  result = call_601296.call(path_601297, query_601298, nil, nil, nil)

var getRoutes* = Call_GetRoutes_601282(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_601283,
                                    base: "/", url: url_GetRoutes_601284,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_601333 = ref object of OpenApiRestCall_600426
proc url_CreateRouteResponse_601335(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateRouteResponse_601334(path: JsonNode; query: JsonNode;
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
  var valid_601336 = path.getOrDefault("apiId")
  valid_601336 = validateParameter(valid_601336, JString, required = true,
                                 default = nil)
  if valid_601336 != nil:
    section.add "apiId", valid_601336
  var valid_601337 = path.getOrDefault("routeId")
  valid_601337 = validateParameter(valid_601337, JString, required = true,
                                 default = nil)
  if valid_601337 != nil:
    section.add "routeId", valid_601337
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
  var valid_601338 = header.getOrDefault("X-Amz-Date")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Date", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Security-Token")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Security-Token", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Content-Sha256", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Algorithm")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Algorithm", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Signature")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Signature", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-SignedHeaders", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Credential")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Credential", valid_601344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601346: Call_CreateRouteResponse_601333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_601346.validator(path, query, header, formData, body)
  let scheme = call_601346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601346.url(scheme.get, call_601346.host, call_601346.base,
                         call_601346.route, valid.getOrDefault("path"))
  result = hook(call_601346, url, valid)

proc call*(call_601347: Call_CreateRouteResponse_601333; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_601348 = newJObject()
  var body_601349 = newJObject()
  add(path_601348, "apiId", newJString(apiId))
  if body != nil:
    body_601349 = body
  add(path_601348, "routeId", newJString(routeId))
  result = call_601347.call(path_601348, nil, nil, nil, body_601349)

var createRouteResponse* = Call_CreateRouteResponse_601333(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_601334, base: "/",
    url: url_CreateRouteResponse_601335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_601315 = ref object of OpenApiRestCall_600426
proc url_GetRouteResponses_601317(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRouteResponses_601316(path: JsonNode; query: JsonNode;
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
  var valid_601318 = path.getOrDefault("apiId")
  valid_601318 = validateParameter(valid_601318, JString, required = true,
                                 default = nil)
  if valid_601318 != nil:
    section.add "apiId", valid_601318
  var valid_601319 = path.getOrDefault("routeId")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "routeId", valid_601319
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601320 = query.getOrDefault("maxResults")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "maxResults", valid_601320
  var valid_601321 = query.getOrDefault("nextToken")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "nextToken", valid_601321
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
  var valid_601322 = header.getOrDefault("X-Amz-Date")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Date", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Security-Token")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Security-Token", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Content-Sha256", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Algorithm")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Algorithm", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Signature")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Signature", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-SignedHeaders", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Credential")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Credential", valid_601328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601329: Call_GetRouteResponses_601315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_601329.validator(path, query, header, formData, body)
  let scheme = call_601329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601329.url(scheme.get, call_601329.host, call_601329.base,
                         call_601329.route, valid.getOrDefault("path"))
  result = hook(call_601329, url, valid)

proc call*(call_601330: Call_GetRouteResponses_601315; apiId: string;
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
  var path_601331 = newJObject()
  var query_601332 = newJObject()
  add(path_601331, "apiId", newJString(apiId))
  add(query_601332, "maxResults", newJString(maxResults))
  add(query_601332, "nextToken", newJString(nextToken))
  add(path_601331, "routeId", newJString(routeId))
  result = call_601330.call(path_601331, query_601332, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_601315(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_601316, base: "/",
    url: url_GetRouteResponses_601317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_601367 = ref object of OpenApiRestCall_600426
proc url_CreateStage_601369(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateStage_601368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601370 = path.getOrDefault("apiId")
  valid_601370 = validateParameter(valid_601370, JString, required = true,
                                 default = nil)
  if valid_601370 != nil:
    section.add "apiId", valid_601370
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
  var valid_601371 = header.getOrDefault("X-Amz-Date")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Date", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Security-Token")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Security-Token", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Content-Sha256", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Algorithm")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Algorithm", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Signature")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Signature", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-SignedHeaders", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Credential")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Credential", valid_601377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601379: Call_CreateStage_601367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_601379.validator(path, query, header, formData, body)
  let scheme = call_601379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601379.url(scheme.get, call_601379.host, call_601379.base,
                         call_601379.route, valid.getOrDefault("path"))
  result = hook(call_601379, url, valid)

proc call*(call_601380: Call_CreateStage_601367; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601381 = newJObject()
  var body_601382 = newJObject()
  add(path_601381, "apiId", newJString(apiId))
  if body != nil:
    body_601382 = body
  result = call_601380.call(path_601381, nil, nil, nil, body_601382)

var createStage* = Call_CreateStage_601367(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_601368,
                                        base: "/", url: url_CreateStage_601369,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_601350 = ref object of OpenApiRestCall_600426
proc url_GetStages_601352(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStages_601351(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601353 = path.getOrDefault("apiId")
  valid_601353 = validateParameter(valid_601353, JString, required = true,
                                 default = nil)
  if valid_601353 != nil:
    section.add "apiId", valid_601353
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_601354 = query.getOrDefault("maxResults")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "maxResults", valid_601354
  var valid_601355 = query.getOrDefault("nextToken")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "nextToken", valid_601355
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
  var valid_601356 = header.getOrDefault("X-Amz-Date")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Date", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Security-Token")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Security-Token", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Algorithm")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Algorithm", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Signature")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Signature", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-SignedHeaders", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Credential")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Credential", valid_601362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601363: Call_GetStages_601350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_601363.validator(path, query, header, formData, body)
  let scheme = call_601363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601363.url(scheme.get, call_601363.host, call_601363.base,
                         call_601363.route, valid.getOrDefault("path"))
  result = hook(call_601363, url, valid)

proc call*(call_601364: Call_GetStages_601350; apiId: string;
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
  var path_601365 = newJObject()
  var query_601366 = newJObject()
  add(path_601365, "apiId", newJString(apiId))
  add(query_601366, "maxResults", newJString(maxResults))
  add(query_601366, "nextToken", newJString(nextToken))
  result = call_601364.call(path_601365, query_601366, nil, nil, nil)

var getStages* = Call_GetStages_601350(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_601351,
                                    base: "/", url: url_GetStages_601352,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_601383 = ref object of OpenApiRestCall_600426
proc url_GetApi_601385(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApi_601384(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601386 = path.getOrDefault("apiId")
  valid_601386 = validateParameter(valid_601386, JString, required = true,
                                 default = nil)
  if valid_601386 != nil:
    section.add "apiId", valid_601386
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
  var valid_601387 = header.getOrDefault("X-Amz-Date")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Date", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Security-Token")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Security-Token", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Content-Sha256", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Algorithm")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Algorithm", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Signature")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Signature", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-SignedHeaders", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Credential")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Credential", valid_601393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601394: Call_GetApi_601383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"))
  result = hook(call_601394, url, valid)

proc call*(call_601395: Call_GetApi_601383; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_601396 = newJObject()
  add(path_601396, "apiId", newJString(apiId))
  result = call_601395.call(path_601396, nil, nil, nil, nil)

var getApi* = Call_GetApi_601383(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_601384, base: "/",
                              url: url_GetApi_601385,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_601411 = ref object of OpenApiRestCall_600426
proc url_UpdateApi_601413(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApi_601412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601414 = path.getOrDefault("apiId")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = nil)
  if valid_601414 != nil:
    section.add "apiId", valid_601414
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
  var valid_601415 = header.getOrDefault("X-Amz-Date")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Date", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Security-Token")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Security-Token", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Content-Sha256", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Algorithm")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Algorithm", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Signature")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Signature", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-SignedHeaders", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Credential")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Credential", valid_601421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601423: Call_UpdateApi_601411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_601423.validator(path, query, header, formData, body)
  let scheme = call_601423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601423.url(scheme.get, call_601423.host, call_601423.base,
                         call_601423.route, valid.getOrDefault("path"))
  result = hook(call_601423, url, valid)

proc call*(call_601424: Call_UpdateApi_601411; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601425 = newJObject()
  var body_601426 = newJObject()
  add(path_601425, "apiId", newJString(apiId))
  if body != nil:
    body_601426 = body
  result = call_601424.call(path_601425, nil, nil, nil, body_601426)

var updateApi* = Call_UpdateApi_601411(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_601412,
                                    base: "/", url: url_UpdateApi_601413,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_601397 = ref object of OpenApiRestCall_600426
proc url_DeleteApi_601399(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApi_601398(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601400 = path.getOrDefault("apiId")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = nil)
  if valid_601400 != nil:
    section.add "apiId", valid_601400
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
  var valid_601401 = header.getOrDefault("X-Amz-Date")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Date", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Security-Token")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Security-Token", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Content-Sha256", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Algorithm")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Algorithm", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Signature")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Signature", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-SignedHeaders", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Credential")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Credential", valid_601407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601408: Call_DeleteApi_601397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_601408.validator(path, query, header, formData, body)
  let scheme = call_601408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601408.url(scheme.get, call_601408.host, call_601408.base,
                         call_601408.route, valid.getOrDefault("path"))
  result = hook(call_601408, url, valid)

proc call*(call_601409: Call_DeleteApi_601397; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_601410 = newJObject()
  add(path_601410, "apiId", newJString(apiId))
  result = call_601409.call(path_601410, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_601397(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_601398,
                                    base: "/", url: url_DeleteApi_601399,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_601427 = ref object of OpenApiRestCall_600426
proc url_GetApiMapping_601429(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApiMapping_601428(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601430 = path.getOrDefault("domainName")
  valid_601430 = validateParameter(valid_601430, JString, required = true,
                                 default = nil)
  if valid_601430 != nil:
    section.add "domainName", valid_601430
  var valid_601431 = path.getOrDefault("apiMappingId")
  valid_601431 = validateParameter(valid_601431, JString, required = true,
                                 default = nil)
  if valid_601431 != nil:
    section.add "apiMappingId", valid_601431
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
  var valid_601432 = header.getOrDefault("X-Amz-Date")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Date", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Security-Token")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Security-Token", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Content-Sha256", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Algorithm")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Algorithm", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Signature")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Signature", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-SignedHeaders", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Credential")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Credential", valid_601438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601439: Call_GetApiMapping_601427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_601439.validator(path, query, header, formData, body)
  let scheme = call_601439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601439.url(scheme.get, call_601439.host, call_601439.base,
                         call_601439.route, valid.getOrDefault("path"))
  result = hook(call_601439, url, valid)

proc call*(call_601440: Call_GetApiMapping_601427; domainName: string;
          apiMappingId: string): Recallable =
  ## getApiMapping
  ## The API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_601441 = newJObject()
  add(path_601441, "domainName", newJString(domainName))
  add(path_601441, "apiMappingId", newJString(apiMappingId))
  result = call_601440.call(path_601441, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_601427(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_601428, base: "/", url: url_GetApiMapping_601429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_601457 = ref object of OpenApiRestCall_600426
proc url_UpdateApiMapping_601459(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApiMapping_601458(path: JsonNode; query: JsonNode;
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
  var valid_601460 = path.getOrDefault("domainName")
  valid_601460 = validateParameter(valid_601460, JString, required = true,
                                 default = nil)
  if valid_601460 != nil:
    section.add "domainName", valid_601460
  var valid_601461 = path.getOrDefault("apiMappingId")
  valid_601461 = validateParameter(valid_601461, JString, required = true,
                                 default = nil)
  if valid_601461 != nil:
    section.add "apiMappingId", valid_601461
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
  var valid_601462 = header.getOrDefault("X-Amz-Date")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Date", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Security-Token")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Security-Token", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Content-Sha256", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Algorithm")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Algorithm", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Signature")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Signature", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-SignedHeaders", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Credential")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Credential", valid_601468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601470: Call_UpdateApiMapping_601457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_601470.validator(path, query, header, formData, body)
  let scheme = call_601470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601470.url(scheme.get, call_601470.host, call_601470.base,
                         call_601470.route, valid.getOrDefault("path"))
  result = hook(call_601470, url, valid)

proc call*(call_601471: Call_UpdateApiMapping_601457; domainName: string;
          apiMappingId: string; body: JsonNode): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  var path_601472 = newJObject()
  var body_601473 = newJObject()
  add(path_601472, "domainName", newJString(domainName))
  add(path_601472, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_601473 = body
  result = call_601471.call(path_601472, nil, nil, nil, body_601473)

var updateApiMapping* = Call_UpdateApiMapping_601457(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_601458, base: "/",
    url: url_UpdateApiMapping_601459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_601442 = ref object of OpenApiRestCall_600426
proc url_DeleteApiMapping_601444(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApiMapping_601443(path: JsonNode; query: JsonNode;
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
  var valid_601445 = path.getOrDefault("domainName")
  valid_601445 = validateParameter(valid_601445, JString, required = true,
                                 default = nil)
  if valid_601445 != nil:
    section.add "domainName", valid_601445
  var valid_601446 = path.getOrDefault("apiMappingId")
  valid_601446 = validateParameter(valid_601446, JString, required = true,
                                 default = nil)
  if valid_601446 != nil:
    section.add "apiMappingId", valid_601446
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
  var valid_601447 = header.getOrDefault("X-Amz-Date")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Date", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Security-Token")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Security-Token", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Content-Sha256", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Algorithm")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Algorithm", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Signature")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Signature", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-SignedHeaders", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Credential")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Credential", valid_601453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601454: Call_DeleteApiMapping_601442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_601454.validator(path, query, header, formData, body)
  let scheme = call_601454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601454.url(scheme.get, call_601454.host, call_601454.base,
                         call_601454.route, valid.getOrDefault("path"))
  result = hook(call_601454, url, valid)

proc call*(call_601455: Call_DeleteApiMapping_601442; domainName: string;
          apiMappingId: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_601456 = newJObject()
  add(path_601456, "domainName", newJString(domainName))
  add(path_601456, "apiMappingId", newJString(apiMappingId))
  result = call_601455.call(path_601456, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_601442(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_601443, base: "/",
    url: url_DeleteApiMapping_601444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_601474 = ref object of OpenApiRestCall_600426
proc url_GetAuthorizer_601476(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAuthorizer_601475(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601477 = path.getOrDefault("apiId")
  valid_601477 = validateParameter(valid_601477, JString, required = true,
                                 default = nil)
  if valid_601477 != nil:
    section.add "apiId", valid_601477
  var valid_601478 = path.getOrDefault("authorizerId")
  valid_601478 = validateParameter(valid_601478, JString, required = true,
                                 default = nil)
  if valid_601478 != nil:
    section.add "authorizerId", valid_601478
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
  var valid_601479 = header.getOrDefault("X-Amz-Date")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Date", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Security-Token")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Security-Token", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Content-Sha256", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Algorithm")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Algorithm", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Signature")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Signature", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-SignedHeaders", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Credential")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Credential", valid_601485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601486: Call_GetAuthorizer_601474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_601486.validator(path, query, header, formData, body)
  let scheme = call_601486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601486.url(scheme.get, call_601486.host, call_601486.base,
                         call_601486.route, valid.getOrDefault("path"))
  result = hook(call_601486, url, valid)

proc call*(call_601487: Call_GetAuthorizer_601474; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_601488 = newJObject()
  add(path_601488, "apiId", newJString(apiId))
  add(path_601488, "authorizerId", newJString(authorizerId))
  result = call_601487.call(path_601488, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_601474(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_601475, base: "/", url: url_GetAuthorizer_601476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_601504 = ref object of OpenApiRestCall_600426
proc url_UpdateAuthorizer_601506(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateAuthorizer_601505(path: JsonNode; query: JsonNode;
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
  var valid_601507 = path.getOrDefault("apiId")
  valid_601507 = validateParameter(valid_601507, JString, required = true,
                                 default = nil)
  if valid_601507 != nil:
    section.add "apiId", valid_601507
  var valid_601508 = path.getOrDefault("authorizerId")
  valid_601508 = validateParameter(valid_601508, JString, required = true,
                                 default = nil)
  if valid_601508 != nil:
    section.add "authorizerId", valid_601508
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
  var valid_601509 = header.getOrDefault("X-Amz-Date")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Date", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Security-Token")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Security-Token", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Content-Sha256", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Algorithm")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Algorithm", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Signature")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Signature", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-SignedHeaders", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Credential")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Credential", valid_601515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601517: Call_UpdateAuthorizer_601504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_601517.validator(path, query, header, formData, body)
  let scheme = call_601517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601517.url(scheme.get, call_601517.host, call_601517.base,
                         call_601517.route, valid.getOrDefault("path"))
  result = hook(call_601517, url, valid)

proc call*(call_601518: Call_UpdateAuthorizer_601504; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_601519 = newJObject()
  var body_601520 = newJObject()
  add(path_601519, "apiId", newJString(apiId))
  add(path_601519, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_601520 = body
  result = call_601518.call(path_601519, nil, nil, nil, body_601520)

var updateAuthorizer* = Call_UpdateAuthorizer_601504(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_601505, base: "/",
    url: url_UpdateAuthorizer_601506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_601489 = ref object of OpenApiRestCall_600426
proc url_DeleteAuthorizer_601491(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteAuthorizer_601490(path: JsonNode; query: JsonNode;
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
  var valid_601492 = path.getOrDefault("apiId")
  valid_601492 = validateParameter(valid_601492, JString, required = true,
                                 default = nil)
  if valid_601492 != nil:
    section.add "apiId", valid_601492
  var valid_601493 = path.getOrDefault("authorizerId")
  valid_601493 = validateParameter(valid_601493, JString, required = true,
                                 default = nil)
  if valid_601493 != nil:
    section.add "authorizerId", valid_601493
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
  var valid_601494 = header.getOrDefault("X-Amz-Date")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Date", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Security-Token")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Security-Token", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Content-Sha256", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Algorithm")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Algorithm", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Signature")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Signature", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-SignedHeaders", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Credential")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Credential", valid_601500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601501: Call_DeleteAuthorizer_601489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_601501.validator(path, query, header, formData, body)
  let scheme = call_601501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601501.url(scheme.get, call_601501.host, call_601501.base,
                         call_601501.route, valid.getOrDefault("path"))
  result = hook(call_601501, url, valid)

proc call*(call_601502: Call_DeleteAuthorizer_601489; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_601503 = newJObject()
  add(path_601503, "apiId", newJString(apiId))
  add(path_601503, "authorizerId", newJString(authorizerId))
  result = call_601502.call(path_601503, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_601489(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_601490, base: "/",
    url: url_DeleteAuthorizer_601491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_601521 = ref object of OpenApiRestCall_600426
proc url_GetDeployment_601523(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeployment_601522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601524 = path.getOrDefault("apiId")
  valid_601524 = validateParameter(valid_601524, JString, required = true,
                                 default = nil)
  if valid_601524 != nil:
    section.add "apiId", valid_601524
  var valid_601525 = path.getOrDefault("deploymentId")
  valid_601525 = validateParameter(valid_601525, JString, required = true,
                                 default = nil)
  if valid_601525 != nil:
    section.add "deploymentId", valid_601525
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
  var valid_601526 = header.getOrDefault("X-Amz-Date")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Date", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Security-Token")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Security-Token", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Content-Sha256", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Algorithm")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Algorithm", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Signature")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Signature", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-SignedHeaders", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Credential")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Credential", valid_601532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601533: Call_GetDeployment_601521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_601533.validator(path, query, header, formData, body)
  let scheme = call_601533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601533.url(scheme.get, call_601533.host, call_601533.base,
                         call_601533.route, valid.getOrDefault("path"))
  result = hook(call_601533, url, valid)

proc call*(call_601534: Call_GetDeployment_601521; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_601535 = newJObject()
  add(path_601535, "apiId", newJString(apiId))
  add(path_601535, "deploymentId", newJString(deploymentId))
  result = call_601534.call(path_601535, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_601521(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_601522, base: "/", url: url_GetDeployment_601523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_601551 = ref object of OpenApiRestCall_600426
proc url_UpdateDeployment_601553(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDeployment_601552(path: JsonNode; query: JsonNode;
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
  var valid_601554 = path.getOrDefault("apiId")
  valid_601554 = validateParameter(valid_601554, JString, required = true,
                                 default = nil)
  if valid_601554 != nil:
    section.add "apiId", valid_601554
  var valid_601555 = path.getOrDefault("deploymentId")
  valid_601555 = validateParameter(valid_601555, JString, required = true,
                                 default = nil)
  if valid_601555 != nil:
    section.add "deploymentId", valid_601555
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
  var valid_601556 = header.getOrDefault("X-Amz-Date")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Date", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Security-Token")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Security-Token", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Content-Sha256", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Algorithm")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Algorithm", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Signature")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Signature", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-SignedHeaders", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Credential")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Credential", valid_601562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601564: Call_UpdateDeployment_601551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_601564.validator(path, query, header, formData, body)
  let scheme = call_601564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601564.url(scheme.get, call_601564.host, call_601564.base,
                         call_601564.route, valid.getOrDefault("path"))
  result = hook(call_601564, url, valid)

proc call*(call_601565: Call_UpdateDeployment_601551; apiId: string;
          deploymentId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  ##   body: JObject (required)
  var path_601566 = newJObject()
  var body_601567 = newJObject()
  add(path_601566, "apiId", newJString(apiId))
  add(path_601566, "deploymentId", newJString(deploymentId))
  if body != nil:
    body_601567 = body
  result = call_601565.call(path_601566, nil, nil, nil, body_601567)

var updateDeployment* = Call_UpdateDeployment_601551(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_601552, base: "/",
    url: url_UpdateDeployment_601553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_601536 = ref object of OpenApiRestCall_600426
proc url_DeleteDeployment_601538(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDeployment_601537(path: JsonNode; query: JsonNode;
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
  var valid_601539 = path.getOrDefault("apiId")
  valid_601539 = validateParameter(valid_601539, JString, required = true,
                                 default = nil)
  if valid_601539 != nil:
    section.add "apiId", valid_601539
  var valid_601540 = path.getOrDefault("deploymentId")
  valid_601540 = validateParameter(valid_601540, JString, required = true,
                                 default = nil)
  if valid_601540 != nil:
    section.add "deploymentId", valid_601540
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
  var valid_601541 = header.getOrDefault("X-Amz-Date")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Date", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Security-Token")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Security-Token", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Content-Sha256", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Algorithm")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Algorithm", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Signature")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Signature", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-SignedHeaders", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Credential")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Credential", valid_601547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601548: Call_DeleteDeployment_601536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_601548.validator(path, query, header, formData, body)
  let scheme = call_601548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601548.url(scheme.get, call_601548.host, call_601548.base,
                         call_601548.route, valid.getOrDefault("path"))
  result = hook(call_601548, url, valid)

proc call*(call_601549: Call_DeleteDeployment_601536; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_601550 = newJObject()
  add(path_601550, "apiId", newJString(apiId))
  add(path_601550, "deploymentId", newJString(deploymentId))
  result = call_601549.call(path_601550, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_601536(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_601537, base: "/",
    url: url_DeleteDeployment_601538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_601568 = ref object of OpenApiRestCall_600426
proc url_GetDomainName_601570(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDomainName_601569(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601571 = path.getOrDefault("domainName")
  valid_601571 = validateParameter(valid_601571, JString, required = true,
                                 default = nil)
  if valid_601571 != nil:
    section.add "domainName", valid_601571
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
  var valid_601572 = header.getOrDefault("X-Amz-Date")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Date", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Security-Token")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Security-Token", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Content-Sha256", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Algorithm")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Algorithm", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Signature")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Signature", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-SignedHeaders", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Credential")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Credential", valid_601578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601579: Call_GetDomainName_601568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_601579.validator(path, query, header, formData, body)
  let scheme = call_601579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601579.url(scheme.get, call_601579.host, call_601579.base,
                         call_601579.route, valid.getOrDefault("path"))
  result = hook(call_601579, url, valid)

proc call*(call_601580: Call_GetDomainName_601568; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_601581 = newJObject()
  add(path_601581, "domainName", newJString(domainName))
  result = call_601580.call(path_601581, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_601568(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_601569,
    base: "/", url: url_GetDomainName_601570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_601596 = ref object of OpenApiRestCall_600426
proc url_UpdateDomainName_601598(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDomainName_601597(path: JsonNode; query: JsonNode;
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
  var valid_601599 = path.getOrDefault("domainName")
  valid_601599 = validateParameter(valid_601599, JString, required = true,
                                 default = nil)
  if valid_601599 != nil:
    section.add "domainName", valid_601599
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
  var valid_601600 = header.getOrDefault("X-Amz-Date")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Date", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Security-Token")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Security-Token", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Content-Sha256", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Algorithm")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Algorithm", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Signature")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Signature", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-SignedHeaders", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Credential")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Credential", valid_601606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601608: Call_UpdateDomainName_601596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_601608.validator(path, query, header, formData, body)
  let scheme = call_601608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601608.url(scheme.get, call_601608.host, call_601608.base,
                         call_601608.route, valid.getOrDefault("path"))
  result = hook(call_601608, url, valid)

proc call*(call_601609: Call_UpdateDomainName_601596; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_601610 = newJObject()
  var body_601611 = newJObject()
  add(path_601610, "domainName", newJString(domainName))
  if body != nil:
    body_601611 = body
  result = call_601609.call(path_601610, nil, nil, nil, body_601611)

var updateDomainName* = Call_UpdateDomainName_601596(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_601597,
    base: "/", url: url_UpdateDomainName_601598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_601582 = ref object of OpenApiRestCall_600426
proc url_DeleteDomainName_601584(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDomainName_601583(path: JsonNode; query: JsonNode;
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
  var valid_601585 = path.getOrDefault("domainName")
  valid_601585 = validateParameter(valid_601585, JString, required = true,
                                 default = nil)
  if valid_601585 != nil:
    section.add "domainName", valid_601585
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
  var valid_601586 = header.getOrDefault("X-Amz-Date")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Date", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Security-Token")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Security-Token", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Content-Sha256", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Algorithm")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Algorithm", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Signature")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Signature", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-SignedHeaders", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Credential")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Credential", valid_601592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601593: Call_DeleteDomainName_601582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_601593.validator(path, query, header, formData, body)
  let scheme = call_601593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601593.url(scheme.get, call_601593.host, call_601593.base,
                         call_601593.route, valid.getOrDefault("path"))
  result = hook(call_601593, url, valid)

proc call*(call_601594: Call_DeleteDomainName_601582; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_601595 = newJObject()
  add(path_601595, "domainName", newJString(domainName))
  result = call_601594.call(path_601595, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_601582(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_601583,
    base: "/", url: url_DeleteDomainName_601584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_601612 = ref object of OpenApiRestCall_600426
proc url_GetIntegration_601614(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIntegration_601613(path: JsonNode; query: JsonNode;
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
  var valid_601615 = path.getOrDefault("apiId")
  valid_601615 = validateParameter(valid_601615, JString, required = true,
                                 default = nil)
  if valid_601615 != nil:
    section.add "apiId", valid_601615
  var valid_601616 = path.getOrDefault("integrationId")
  valid_601616 = validateParameter(valid_601616, JString, required = true,
                                 default = nil)
  if valid_601616 != nil:
    section.add "integrationId", valid_601616
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
  var valid_601617 = header.getOrDefault("X-Amz-Date")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Date", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Security-Token")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Security-Token", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Content-Sha256", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Algorithm")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Algorithm", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Signature")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Signature", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-SignedHeaders", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Credential")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Credential", valid_601623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601624: Call_GetIntegration_601612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_601624.validator(path, query, header, formData, body)
  let scheme = call_601624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601624.url(scheme.get, call_601624.host, call_601624.base,
                         call_601624.route, valid.getOrDefault("path"))
  result = hook(call_601624, url, valid)

proc call*(call_601625: Call_GetIntegration_601612; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_601626 = newJObject()
  add(path_601626, "apiId", newJString(apiId))
  add(path_601626, "integrationId", newJString(integrationId))
  result = call_601625.call(path_601626, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_601612(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_601613, base: "/", url: url_GetIntegration_601614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_601642 = ref object of OpenApiRestCall_600426
proc url_UpdateIntegration_601644(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateIntegration_601643(path: JsonNode; query: JsonNode;
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
  var valid_601645 = path.getOrDefault("apiId")
  valid_601645 = validateParameter(valid_601645, JString, required = true,
                                 default = nil)
  if valid_601645 != nil:
    section.add "apiId", valid_601645
  var valid_601646 = path.getOrDefault("integrationId")
  valid_601646 = validateParameter(valid_601646, JString, required = true,
                                 default = nil)
  if valid_601646 != nil:
    section.add "integrationId", valid_601646
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
  var valid_601647 = header.getOrDefault("X-Amz-Date")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Date", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Security-Token")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Security-Token", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Content-Sha256", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Algorithm")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Algorithm", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Signature")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Signature", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-SignedHeaders", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Credential")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Credential", valid_601653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601655: Call_UpdateIntegration_601642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_601655.validator(path, query, header, formData, body)
  let scheme = call_601655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601655.url(scheme.get, call_601655.host, call_601655.base,
                         call_601655.route, valid.getOrDefault("path"))
  result = hook(call_601655, url, valid)

proc call*(call_601656: Call_UpdateIntegration_601642; apiId: string; body: JsonNode;
          integrationId: string): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_601657 = newJObject()
  var body_601658 = newJObject()
  add(path_601657, "apiId", newJString(apiId))
  if body != nil:
    body_601658 = body
  add(path_601657, "integrationId", newJString(integrationId))
  result = call_601656.call(path_601657, nil, nil, nil, body_601658)

var updateIntegration* = Call_UpdateIntegration_601642(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_601643, base: "/",
    url: url_UpdateIntegration_601644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_601627 = ref object of OpenApiRestCall_600426
proc url_DeleteIntegration_601629(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteIntegration_601628(path: JsonNode; query: JsonNode;
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
  var valid_601630 = path.getOrDefault("apiId")
  valid_601630 = validateParameter(valid_601630, JString, required = true,
                                 default = nil)
  if valid_601630 != nil:
    section.add "apiId", valid_601630
  var valid_601631 = path.getOrDefault("integrationId")
  valid_601631 = validateParameter(valid_601631, JString, required = true,
                                 default = nil)
  if valid_601631 != nil:
    section.add "integrationId", valid_601631
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
  var valid_601632 = header.getOrDefault("X-Amz-Date")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Date", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Security-Token")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Security-Token", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Content-Sha256", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Algorithm")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Algorithm", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Signature")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Signature", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-SignedHeaders", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Credential")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Credential", valid_601638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601639: Call_DeleteIntegration_601627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_601639.validator(path, query, header, formData, body)
  let scheme = call_601639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601639.url(scheme.get, call_601639.host, call_601639.base,
                         call_601639.route, valid.getOrDefault("path"))
  result = hook(call_601639, url, valid)

proc call*(call_601640: Call_DeleteIntegration_601627; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_601641 = newJObject()
  add(path_601641, "apiId", newJString(apiId))
  add(path_601641, "integrationId", newJString(integrationId))
  result = call_601640.call(path_601641, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_601627(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_601628, base: "/",
    url: url_DeleteIntegration_601629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_601659 = ref object of OpenApiRestCall_600426
proc url_GetIntegrationResponse_601661(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIntegrationResponse_601660(path: JsonNode; query: JsonNode;
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
  var valid_601662 = path.getOrDefault("integrationResponseId")
  valid_601662 = validateParameter(valid_601662, JString, required = true,
                                 default = nil)
  if valid_601662 != nil:
    section.add "integrationResponseId", valid_601662
  var valid_601663 = path.getOrDefault("apiId")
  valid_601663 = validateParameter(valid_601663, JString, required = true,
                                 default = nil)
  if valid_601663 != nil:
    section.add "apiId", valid_601663
  var valid_601664 = path.getOrDefault("integrationId")
  valid_601664 = validateParameter(valid_601664, JString, required = true,
                                 default = nil)
  if valid_601664 != nil:
    section.add "integrationId", valid_601664
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
  var valid_601665 = header.getOrDefault("X-Amz-Date")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Date", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Security-Token")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Security-Token", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Content-Sha256", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Algorithm")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Algorithm", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Signature")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Signature", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-SignedHeaders", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Credential")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Credential", valid_601671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601672: Call_GetIntegrationResponse_601659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_601672.validator(path, query, header, formData, body)
  let scheme = call_601672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601672.url(scheme.get, call_601672.host, call_601672.base,
                         call_601672.route, valid.getOrDefault("path"))
  result = hook(call_601672, url, valid)

proc call*(call_601673: Call_GetIntegrationResponse_601659;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_601674 = newJObject()
  add(path_601674, "integrationResponseId", newJString(integrationResponseId))
  add(path_601674, "apiId", newJString(apiId))
  add(path_601674, "integrationId", newJString(integrationId))
  result = call_601673.call(path_601674, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_601659(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_601660, base: "/",
    url: url_GetIntegrationResponse_601661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_601691 = ref object of OpenApiRestCall_600426
proc url_UpdateIntegrationResponse_601693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateIntegrationResponse_601692(path: JsonNode; query: JsonNode;
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
  var valid_601694 = path.getOrDefault("integrationResponseId")
  valid_601694 = validateParameter(valid_601694, JString, required = true,
                                 default = nil)
  if valid_601694 != nil:
    section.add "integrationResponseId", valid_601694
  var valid_601695 = path.getOrDefault("apiId")
  valid_601695 = validateParameter(valid_601695, JString, required = true,
                                 default = nil)
  if valid_601695 != nil:
    section.add "apiId", valid_601695
  var valid_601696 = path.getOrDefault("integrationId")
  valid_601696 = validateParameter(valid_601696, JString, required = true,
                                 default = nil)
  if valid_601696 != nil:
    section.add "integrationId", valid_601696
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
  var valid_601697 = header.getOrDefault("X-Amz-Date")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Date", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Security-Token")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Security-Token", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Content-Sha256", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-Algorithm")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-Algorithm", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Signature")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Signature", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-SignedHeaders", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Credential")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Credential", valid_601703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601705: Call_UpdateIntegrationResponse_601691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_601705.validator(path, query, header, formData, body)
  let scheme = call_601705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601705.url(scheme.get, call_601705.host, call_601705.base,
                         call_601705.route, valid.getOrDefault("path"))
  result = hook(call_601705, url, valid)

proc call*(call_601706: Call_UpdateIntegrationResponse_601691;
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
  var path_601707 = newJObject()
  var body_601708 = newJObject()
  add(path_601707, "integrationResponseId", newJString(integrationResponseId))
  add(path_601707, "apiId", newJString(apiId))
  if body != nil:
    body_601708 = body
  add(path_601707, "integrationId", newJString(integrationId))
  result = call_601706.call(path_601707, nil, nil, nil, body_601708)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_601691(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_601692, base: "/",
    url: url_UpdateIntegrationResponse_601693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_601675 = ref object of OpenApiRestCall_600426
proc url_DeleteIntegrationResponse_601677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteIntegrationResponse_601676(path: JsonNode; query: JsonNode;
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
  var valid_601678 = path.getOrDefault("integrationResponseId")
  valid_601678 = validateParameter(valid_601678, JString, required = true,
                                 default = nil)
  if valid_601678 != nil:
    section.add "integrationResponseId", valid_601678
  var valid_601679 = path.getOrDefault("apiId")
  valid_601679 = validateParameter(valid_601679, JString, required = true,
                                 default = nil)
  if valid_601679 != nil:
    section.add "apiId", valid_601679
  var valid_601680 = path.getOrDefault("integrationId")
  valid_601680 = validateParameter(valid_601680, JString, required = true,
                                 default = nil)
  if valid_601680 != nil:
    section.add "integrationId", valid_601680
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
  var valid_601681 = header.getOrDefault("X-Amz-Date")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Date", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Security-Token")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Security-Token", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Content-Sha256", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Algorithm")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Algorithm", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Signature")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Signature", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-SignedHeaders", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-Credential")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Credential", valid_601687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601688: Call_DeleteIntegrationResponse_601675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_601688.validator(path, query, header, formData, body)
  let scheme = call_601688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601688.url(scheme.get, call_601688.host, call_601688.base,
                         call_601688.route, valid.getOrDefault("path"))
  result = hook(call_601688, url, valid)

proc call*(call_601689: Call_DeleteIntegrationResponse_601675;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_601690 = newJObject()
  add(path_601690, "integrationResponseId", newJString(integrationResponseId))
  add(path_601690, "apiId", newJString(apiId))
  add(path_601690, "integrationId", newJString(integrationId))
  result = call_601689.call(path_601690, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_601675(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_601676, base: "/",
    url: url_DeleteIntegrationResponse_601677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_601709 = ref object of OpenApiRestCall_600426
proc url_GetModel_601711(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetModel_601710(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601712 = path.getOrDefault("apiId")
  valid_601712 = validateParameter(valid_601712, JString, required = true,
                                 default = nil)
  if valid_601712 != nil:
    section.add "apiId", valid_601712
  var valid_601713 = path.getOrDefault("modelId")
  valid_601713 = validateParameter(valid_601713, JString, required = true,
                                 default = nil)
  if valid_601713 != nil:
    section.add "modelId", valid_601713
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
  var valid_601714 = header.getOrDefault("X-Amz-Date")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Date", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Security-Token")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Security-Token", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Content-Sha256", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Algorithm")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Algorithm", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Signature")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Signature", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-SignedHeaders", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-Credential")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Credential", valid_601720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601721: Call_GetModel_601709; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_601721.validator(path, query, header, formData, body)
  let scheme = call_601721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601721.url(scheme.get, call_601721.host, call_601721.base,
                         call_601721.route, valid.getOrDefault("path"))
  result = hook(call_601721, url, valid)

proc call*(call_601722: Call_GetModel_601709; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_601723 = newJObject()
  add(path_601723, "apiId", newJString(apiId))
  add(path_601723, "modelId", newJString(modelId))
  result = call_601722.call(path_601723, nil, nil, nil, nil)

var getModel* = Call_GetModel_601709(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_601710, base: "/",
                                  url: url_GetModel_601711,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_601739 = ref object of OpenApiRestCall_600426
proc url_UpdateModel_601741(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateModel_601740(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601742 = path.getOrDefault("apiId")
  valid_601742 = validateParameter(valid_601742, JString, required = true,
                                 default = nil)
  if valid_601742 != nil:
    section.add "apiId", valid_601742
  var valid_601743 = path.getOrDefault("modelId")
  valid_601743 = validateParameter(valid_601743, JString, required = true,
                                 default = nil)
  if valid_601743 != nil:
    section.add "modelId", valid_601743
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
  var valid_601744 = header.getOrDefault("X-Amz-Date")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Date", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Security-Token")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Security-Token", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Content-Sha256", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Algorithm")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Algorithm", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Signature")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Signature", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-SignedHeaders", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-Credential")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-Credential", valid_601750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601752: Call_UpdateModel_601739; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_601752.validator(path, query, header, formData, body)
  let scheme = call_601752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601752.url(scheme.get, call_601752.host, call_601752.base,
                         call_601752.route, valid.getOrDefault("path"))
  result = hook(call_601752, url, valid)

proc call*(call_601753: Call_UpdateModel_601739; apiId: string; modelId: string;
          body: JsonNode): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  ##   body: JObject (required)
  var path_601754 = newJObject()
  var body_601755 = newJObject()
  add(path_601754, "apiId", newJString(apiId))
  add(path_601754, "modelId", newJString(modelId))
  if body != nil:
    body_601755 = body
  result = call_601753.call(path_601754, nil, nil, nil, body_601755)

var updateModel* = Call_UpdateModel_601739(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_601740,
                                        base: "/", url: url_UpdateModel_601741,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_601724 = ref object of OpenApiRestCall_600426
proc url_DeleteModel_601726(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteModel_601725(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601727 = path.getOrDefault("apiId")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = nil)
  if valid_601727 != nil:
    section.add "apiId", valid_601727
  var valid_601728 = path.getOrDefault("modelId")
  valid_601728 = validateParameter(valid_601728, JString, required = true,
                                 default = nil)
  if valid_601728 != nil:
    section.add "modelId", valid_601728
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
  var valid_601729 = header.getOrDefault("X-Amz-Date")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Date", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Security-Token")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Security-Token", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Content-Sha256", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Algorithm")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Algorithm", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Signature")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Signature", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-SignedHeaders", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-Credential")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-Credential", valid_601735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601736: Call_DeleteModel_601724; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_601736.validator(path, query, header, formData, body)
  let scheme = call_601736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601736.url(scheme.get, call_601736.host, call_601736.base,
                         call_601736.route, valid.getOrDefault("path"))
  result = hook(call_601736, url, valid)

proc call*(call_601737: Call_DeleteModel_601724; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_601738 = newJObject()
  add(path_601738, "apiId", newJString(apiId))
  add(path_601738, "modelId", newJString(modelId))
  result = call_601737.call(path_601738, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_601724(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_601725,
                                        base: "/", url: url_DeleteModel_601726,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_601756 = ref object of OpenApiRestCall_600426
proc url_GetRoute_601758(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRoute_601757(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601759 = path.getOrDefault("apiId")
  valid_601759 = validateParameter(valid_601759, JString, required = true,
                                 default = nil)
  if valid_601759 != nil:
    section.add "apiId", valid_601759
  var valid_601760 = path.getOrDefault("routeId")
  valid_601760 = validateParameter(valid_601760, JString, required = true,
                                 default = nil)
  if valid_601760 != nil:
    section.add "routeId", valid_601760
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
  var valid_601761 = header.getOrDefault("X-Amz-Date")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Date", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Security-Token")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Security-Token", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Content-Sha256", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Algorithm")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Algorithm", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Signature")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Signature", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-SignedHeaders", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Credential")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Credential", valid_601767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601768: Call_GetRoute_601756; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_601768.validator(path, query, header, formData, body)
  let scheme = call_601768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601768.url(scheme.get, call_601768.host, call_601768.base,
                         call_601768.route, valid.getOrDefault("path"))
  result = hook(call_601768, url, valid)

proc call*(call_601769: Call_GetRoute_601756; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_601770 = newJObject()
  add(path_601770, "apiId", newJString(apiId))
  add(path_601770, "routeId", newJString(routeId))
  result = call_601769.call(path_601770, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_601756(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_601757, base: "/",
                                  url: url_GetRoute_601758,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_601786 = ref object of OpenApiRestCall_600426
proc url_UpdateRoute_601788(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateRoute_601787(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601789 = path.getOrDefault("apiId")
  valid_601789 = validateParameter(valid_601789, JString, required = true,
                                 default = nil)
  if valid_601789 != nil:
    section.add "apiId", valid_601789
  var valid_601790 = path.getOrDefault("routeId")
  valid_601790 = validateParameter(valid_601790, JString, required = true,
                                 default = nil)
  if valid_601790 != nil:
    section.add "routeId", valid_601790
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
  var valid_601791 = header.getOrDefault("X-Amz-Date")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Date", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Security-Token")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Security-Token", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Content-Sha256", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Algorithm")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Algorithm", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Signature")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Signature", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-SignedHeaders", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Credential")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Credential", valid_601797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601799: Call_UpdateRoute_601786; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_601799.validator(path, query, header, formData, body)
  let scheme = call_601799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601799.url(scheme.get, call_601799.host, call_601799.base,
                         call_601799.route, valid.getOrDefault("path"))
  result = hook(call_601799, url, valid)

proc call*(call_601800: Call_UpdateRoute_601786; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_601801 = newJObject()
  var body_601802 = newJObject()
  add(path_601801, "apiId", newJString(apiId))
  if body != nil:
    body_601802 = body
  add(path_601801, "routeId", newJString(routeId))
  result = call_601800.call(path_601801, nil, nil, nil, body_601802)

var updateRoute* = Call_UpdateRoute_601786(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_601787,
                                        base: "/", url: url_UpdateRoute_601788,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_601771 = ref object of OpenApiRestCall_600426
proc url_DeleteRoute_601773(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteRoute_601772(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601774 = path.getOrDefault("apiId")
  valid_601774 = validateParameter(valid_601774, JString, required = true,
                                 default = nil)
  if valid_601774 != nil:
    section.add "apiId", valid_601774
  var valid_601775 = path.getOrDefault("routeId")
  valid_601775 = validateParameter(valid_601775, JString, required = true,
                                 default = nil)
  if valid_601775 != nil:
    section.add "routeId", valid_601775
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
  var valid_601776 = header.getOrDefault("X-Amz-Date")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Date", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Security-Token")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Security-Token", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Content-Sha256", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Algorithm")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Algorithm", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Signature")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Signature", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-SignedHeaders", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-Credential")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-Credential", valid_601782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601783: Call_DeleteRoute_601771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_601783.validator(path, query, header, formData, body)
  let scheme = call_601783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601783.url(scheme.get, call_601783.host, call_601783.base,
                         call_601783.route, valid.getOrDefault("path"))
  result = hook(call_601783, url, valid)

proc call*(call_601784: Call_DeleteRoute_601771; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_601785 = newJObject()
  add(path_601785, "apiId", newJString(apiId))
  add(path_601785, "routeId", newJString(routeId))
  result = call_601784.call(path_601785, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_601771(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_601772,
                                        base: "/", url: url_DeleteRoute_601773,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_601803 = ref object of OpenApiRestCall_600426
proc url_GetRouteResponse_601805(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRouteResponse_601804(path: JsonNode; query: JsonNode;
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
  var valid_601806 = path.getOrDefault("apiId")
  valid_601806 = validateParameter(valid_601806, JString, required = true,
                                 default = nil)
  if valid_601806 != nil:
    section.add "apiId", valid_601806
  var valid_601807 = path.getOrDefault("routeResponseId")
  valid_601807 = validateParameter(valid_601807, JString, required = true,
                                 default = nil)
  if valid_601807 != nil:
    section.add "routeResponseId", valid_601807
  var valid_601808 = path.getOrDefault("routeId")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = nil)
  if valid_601808 != nil:
    section.add "routeId", valid_601808
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
  var valid_601809 = header.getOrDefault("X-Amz-Date")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Date", valid_601809
  var valid_601810 = header.getOrDefault("X-Amz-Security-Token")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Security-Token", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Content-Sha256", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Algorithm")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Algorithm", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Signature")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Signature", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-SignedHeaders", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Credential")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Credential", valid_601815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601816: Call_GetRouteResponse_601803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_601816.validator(path, query, header, formData, body)
  let scheme = call_601816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601816.url(scheme.get, call_601816.host, call_601816.base,
                         call_601816.route, valid.getOrDefault("path"))
  result = hook(call_601816, url, valid)

proc call*(call_601817: Call_GetRouteResponse_601803; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_601818 = newJObject()
  add(path_601818, "apiId", newJString(apiId))
  add(path_601818, "routeResponseId", newJString(routeResponseId))
  add(path_601818, "routeId", newJString(routeId))
  result = call_601817.call(path_601818, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_601803(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_601804, base: "/",
    url: url_GetRouteResponse_601805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_601835 = ref object of OpenApiRestCall_600426
proc url_UpdateRouteResponse_601837(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateRouteResponse_601836(path: JsonNode; query: JsonNode;
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
  var valid_601838 = path.getOrDefault("apiId")
  valid_601838 = validateParameter(valid_601838, JString, required = true,
                                 default = nil)
  if valid_601838 != nil:
    section.add "apiId", valid_601838
  var valid_601839 = path.getOrDefault("routeResponseId")
  valid_601839 = validateParameter(valid_601839, JString, required = true,
                                 default = nil)
  if valid_601839 != nil:
    section.add "routeResponseId", valid_601839
  var valid_601840 = path.getOrDefault("routeId")
  valid_601840 = validateParameter(valid_601840, JString, required = true,
                                 default = nil)
  if valid_601840 != nil:
    section.add "routeId", valid_601840
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
  var valid_601841 = header.getOrDefault("X-Amz-Date")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Date", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Security-Token")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Security-Token", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Content-Sha256", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Algorithm")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Algorithm", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Signature")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Signature", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-SignedHeaders", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Credential")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Credential", valid_601847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601849: Call_UpdateRouteResponse_601835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_601849.validator(path, query, header, formData, body)
  let scheme = call_601849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601849.url(scheme.get, call_601849.host, call_601849.base,
                         call_601849.route, valid.getOrDefault("path"))
  result = hook(call_601849, url, valid)

proc call*(call_601850: Call_UpdateRouteResponse_601835; apiId: string;
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
  var path_601851 = newJObject()
  var body_601852 = newJObject()
  add(path_601851, "apiId", newJString(apiId))
  add(path_601851, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_601852 = body
  add(path_601851, "routeId", newJString(routeId))
  result = call_601850.call(path_601851, nil, nil, nil, body_601852)

var updateRouteResponse* = Call_UpdateRouteResponse_601835(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_601836, base: "/",
    url: url_UpdateRouteResponse_601837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_601819 = ref object of OpenApiRestCall_600426
proc url_DeleteRouteResponse_601821(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteRouteResponse_601820(path: JsonNode; query: JsonNode;
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
  var valid_601822 = path.getOrDefault("apiId")
  valid_601822 = validateParameter(valid_601822, JString, required = true,
                                 default = nil)
  if valid_601822 != nil:
    section.add "apiId", valid_601822
  var valid_601823 = path.getOrDefault("routeResponseId")
  valid_601823 = validateParameter(valid_601823, JString, required = true,
                                 default = nil)
  if valid_601823 != nil:
    section.add "routeResponseId", valid_601823
  var valid_601824 = path.getOrDefault("routeId")
  valid_601824 = validateParameter(valid_601824, JString, required = true,
                                 default = nil)
  if valid_601824 != nil:
    section.add "routeId", valid_601824
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
  var valid_601825 = header.getOrDefault("X-Amz-Date")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Date", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-Security-Token")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Security-Token", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Content-Sha256", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Algorithm")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Algorithm", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Signature")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Signature", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-SignedHeaders", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Credential")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Credential", valid_601831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601832: Call_DeleteRouteResponse_601819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_601832.validator(path, query, header, formData, body)
  let scheme = call_601832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601832.url(scheme.get, call_601832.host, call_601832.base,
                         call_601832.route, valid.getOrDefault("path"))
  result = hook(call_601832, url, valid)

proc call*(call_601833: Call_DeleteRouteResponse_601819; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_601834 = newJObject()
  add(path_601834, "apiId", newJString(apiId))
  add(path_601834, "routeResponseId", newJString(routeResponseId))
  add(path_601834, "routeId", newJString(routeId))
  result = call_601833.call(path_601834, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_601819(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_601820, base: "/",
    url: url_DeleteRouteResponse_601821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_601853 = ref object of OpenApiRestCall_600426
proc url_GetStage_601855(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStage_601854(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601856 = path.getOrDefault("stageName")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = nil)
  if valid_601856 != nil:
    section.add "stageName", valid_601856
  var valid_601857 = path.getOrDefault("apiId")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = nil)
  if valid_601857 != nil:
    section.add "apiId", valid_601857
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
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Content-Sha256", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Signature")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Signature", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-SignedHeaders", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Credential")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Credential", valid_601864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601865: Call_GetStage_601853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_601865.validator(path, query, header, formData, body)
  let scheme = call_601865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601865.url(scheme.get, call_601865.host, call_601865.base,
                         call_601865.route, valid.getOrDefault("path"))
  result = hook(call_601865, url, valid)

proc call*(call_601866: Call_GetStage_601853; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_601867 = newJObject()
  add(path_601867, "stageName", newJString(stageName))
  add(path_601867, "apiId", newJString(apiId))
  result = call_601866.call(path_601867, nil, nil, nil, nil)

var getStage* = Call_GetStage_601853(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_601854, base: "/",
                                  url: url_GetStage_601855,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_601883 = ref object of OpenApiRestCall_600426
proc url_UpdateStage_601885(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateStage_601884(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601886 = path.getOrDefault("stageName")
  valid_601886 = validateParameter(valid_601886, JString, required = true,
                                 default = nil)
  if valid_601886 != nil:
    section.add "stageName", valid_601886
  var valid_601887 = path.getOrDefault("apiId")
  valid_601887 = validateParameter(valid_601887, JString, required = true,
                                 default = nil)
  if valid_601887 != nil:
    section.add "apiId", valid_601887
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
  var valid_601888 = header.getOrDefault("X-Amz-Date")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-Date", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-Security-Token")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-Security-Token", valid_601889
  var valid_601890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-Content-Sha256", valid_601890
  var valid_601891 = header.getOrDefault("X-Amz-Algorithm")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "X-Amz-Algorithm", valid_601891
  var valid_601892 = header.getOrDefault("X-Amz-Signature")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "X-Amz-Signature", valid_601892
  var valid_601893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "X-Amz-SignedHeaders", valid_601893
  var valid_601894 = header.getOrDefault("X-Amz-Credential")
  valid_601894 = validateParameter(valid_601894, JString, required = false,
                                 default = nil)
  if valid_601894 != nil:
    section.add "X-Amz-Credential", valid_601894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601896: Call_UpdateStage_601883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_601896.validator(path, query, header, formData, body)
  let scheme = call_601896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601896.url(scheme.get, call_601896.host, call_601896.base,
                         call_601896.route, valid.getOrDefault("path"))
  result = hook(call_601896, url, valid)

proc call*(call_601897: Call_UpdateStage_601883; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_601898 = newJObject()
  var body_601899 = newJObject()
  add(path_601898, "stageName", newJString(stageName))
  add(path_601898, "apiId", newJString(apiId))
  if body != nil:
    body_601899 = body
  result = call_601897.call(path_601898, nil, nil, nil, body_601899)

var updateStage* = Call_UpdateStage_601883(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_601884,
                                        base: "/", url: url_UpdateStage_601885,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_601868 = ref object of OpenApiRestCall_600426
proc url_DeleteStage_601870(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteStage_601869(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601871 = path.getOrDefault("stageName")
  valid_601871 = validateParameter(valid_601871, JString, required = true,
                                 default = nil)
  if valid_601871 != nil:
    section.add "stageName", valid_601871
  var valid_601872 = path.getOrDefault("apiId")
  valid_601872 = validateParameter(valid_601872, JString, required = true,
                                 default = nil)
  if valid_601872 != nil:
    section.add "apiId", valid_601872
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
  var valid_601873 = header.getOrDefault("X-Amz-Date")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Date", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-Security-Token")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Security-Token", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Content-Sha256", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Algorithm")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Algorithm", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Signature")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Signature", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-SignedHeaders", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-Credential")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-Credential", valid_601879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601880: Call_DeleteStage_601868; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_601880.validator(path, query, header, formData, body)
  let scheme = call_601880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601880.url(scheme.get, call_601880.host, call_601880.base,
                         call_601880.route, valid.getOrDefault("path"))
  result = hook(call_601880, url, valid)

proc call*(call_601881: Call_DeleteStage_601868; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_601882 = newJObject()
  add(path_601882, "stageName", newJString(stageName))
  add(path_601882, "apiId", newJString(apiId))
  result = call_601881.call(path_601882, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_601868(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_601869,
                                        base: "/", url: url_DeleteStage_601870,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_601900 = ref object of OpenApiRestCall_600426
proc url_GetModelTemplate_601902(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetModelTemplate_601901(path: JsonNode; query: JsonNode;
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
  var valid_601903 = path.getOrDefault("apiId")
  valid_601903 = validateParameter(valid_601903, JString, required = true,
                                 default = nil)
  if valid_601903 != nil:
    section.add "apiId", valid_601903
  var valid_601904 = path.getOrDefault("modelId")
  valid_601904 = validateParameter(valid_601904, JString, required = true,
                                 default = nil)
  if valid_601904 != nil:
    section.add "modelId", valid_601904
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
  var valid_601905 = header.getOrDefault("X-Amz-Date")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Date", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Security-Token")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Security-Token", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-Content-Sha256", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-Algorithm")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Algorithm", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-Signature")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Signature", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-SignedHeaders", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Credential")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Credential", valid_601911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601912: Call_GetModelTemplate_601900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_601912.validator(path, query, header, formData, body)
  let scheme = call_601912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601912.url(scheme.get, call_601912.host, call_601912.base,
                         call_601912.route, valid.getOrDefault("path"))
  result = hook(call_601912, url, valid)

proc call*(call_601913: Call_GetModelTemplate_601900; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_601914 = newJObject()
  add(path_601914, "apiId", newJString(apiId))
  add(path_601914, "modelId", newJString(modelId))
  result = call_601913.call(path_601914, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_601900(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_601901, base: "/",
    url: url_GetModelTemplate_601902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601929 = ref object of OpenApiRestCall_600426
proc url_TagResource_601931(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_601930(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601932 = path.getOrDefault("resource-arn")
  valid_601932 = validateParameter(valid_601932, JString, required = true,
                                 default = nil)
  if valid_601932 != nil:
    section.add "resource-arn", valid_601932
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
  var valid_601933 = header.getOrDefault("X-Amz-Date")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Date", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Security-Token")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Security-Token", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Content-Sha256", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Algorithm")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Algorithm", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Signature")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Signature", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-SignedHeaders", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-Credential")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-Credential", valid_601939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601941: Call_TagResource_601929; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tag an APIGW resource
  ## 
  let valid = call_601941.validator(path, query, header, formData, body)
  let scheme = call_601941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601941.url(scheme.get, call_601941.host, call_601941.base,
                         call_601941.route, valid.getOrDefault("path"))
  result = hook(call_601941, url, valid)

proc call*(call_601942: Call_TagResource_601929; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tag an APIGW resource
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  ##   body: JObject (required)
  var path_601943 = newJObject()
  var body_601944 = newJObject()
  add(path_601943, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_601944 = body
  result = call_601942.call(path_601943, nil, nil, nil, body_601944)

var tagResource* = Call_TagResource_601929(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_601930,
                                        base: "/", url: url_TagResource_601931,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_601915 = ref object of OpenApiRestCall_600426
proc url_GetTags_601917(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetTags_601916(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601918 = path.getOrDefault("resource-arn")
  valid_601918 = validateParameter(valid_601918, JString, required = true,
                                 default = nil)
  if valid_601918 != nil:
    section.add "resource-arn", valid_601918
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
  var valid_601919 = header.getOrDefault("X-Amz-Date")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Date", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Security-Token")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Security-Token", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Content-Sha256", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-Algorithm")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-Algorithm", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Signature")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Signature", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-SignedHeaders", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Credential")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Credential", valid_601925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601926: Call_GetTags_601915; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Tags for an API.
  ## 
  let valid = call_601926.validator(path, query, header, formData, body)
  let scheme = call_601926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601926.url(scheme.get, call_601926.host, call_601926.base,
                         call_601926.route, valid.getOrDefault("path"))
  result = hook(call_601926, url, valid)

proc call*(call_601927: Call_GetTags_601915; resourceArn: string): Recallable =
  ## getTags
  ## Gets the Tags for an API.
  ##   resourceArn: string (required)
  var path_601928 = newJObject()
  add(path_601928, "resource-arn", newJString(resourceArn))
  result = call_601927.call(path_601928, nil, nil, nil, nil)

var getTags* = Call_GetTags_601915(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_601916, base: "/",
                                url: url_GetTags_601917,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601945 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601947(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_601946(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601948 = path.getOrDefault("resource-arn")
  valid_601948 = validateParameter(valid_601948, JString, required = true,
                                 default = nil)
  if valid_601948 != nil:
    section.add "resource-arn", valid_601948
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601949 = query.getOrDefault("tagKeys")
  valid_601949 = validateParameter(valid_601949, JArray, required = true, default = nil)
  if valid_601949 != nil:
    section.add "tagKeys", valid_601949
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
  var valid_601950 = header.getOrDefault("X-Amz-Date")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Date", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Security-Token")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Security-Token", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Content-Sha256", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Algorithm")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Algorithm", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-Signature")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Signature", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-SignedHeaders", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Credential")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Credential", valid_601956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601957: Call_UntagResource_601945; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untag an APIGW resource
  ## 
  let valid = call_601957.validator(path, query, header, formData, body)
  let scheme = call_601957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601957.url(scheme.get, call_601957.host, call_601957.base,
                         call_601957.route, valid.getOrDefault("path"))
  result = hook(call_601957, url, valid)

proc call*(call_601958: Call_UntagResource_601945; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Untag an APIGW resource
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  var path_601959 = newJObject()
  var query_601960 = newJObject()
  if tagKeys != nil:
    query_601960.add "tagKeys", tagKeys
  add(path_601959, "resource-arn", newJString(resourceArn))
  result = call_601958.call(path_601959, query_601960, nil, nil, nil)

var untagResource* = Call_UntagResource_601945(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_601946,
    base: "/", url: url_UntagResource_601947, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
