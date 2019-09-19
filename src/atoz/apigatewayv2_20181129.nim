
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_CreateApi_773190 = ref object of OpenApiRestCall_772597
proc url_CreateApi_773192(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApi_773191(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773193 = header.getOrDefault("X-Amz-Date")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Date", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Security-Token")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Security-Token", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Content-Sha256", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Algorithm")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Algorithm", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Signature")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Signature", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-SignedHeaders", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Credential")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Credential", valid_773199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773201: Call_CreateApi_773190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_773201.validator(path, query, header, formData, body)
  let scheme = call_773201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773201.url(scheme.get, call_773201.host, call_773201.base,
                         call_773201.route, valid.getOrDefault("path"))
  result = hook(call_773201, url, valid)

proc call*(call_773202: Call_CreateApi_773190; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_773203 = newJObject()
  if body != nil:
    body_773203 = body
  result = call_773202.call(nil, nil, nil, nil, body_773203)

var createApi* = Call_CreateApi_773190(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_773191,
                                    base: "/", url: url_CreateApi_773192,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_772933 = ref object of OpenApiRestCall_772597
proc url_GetApis_772935(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApis_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773047 = query.getOrDefault("maxResults")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "maxResults", valid_773047
  var valid_773048 = query.getOrDefault("nextToken")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "nextToken", valid_773048
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
  var valid_773049 = header.getOrDefault("X-Amz-Date")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Date", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Security-Token")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Security-Token", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Content-Sha256", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-Algorithm")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-Algorithm", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Signature")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Signature", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-SignedHeaders", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Credential")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Credential", valid_773055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773078: Call_GetApis_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_773078.validator(path, query, header, formData, body)
  let scheme = call_773078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773078.url(scheme.get, call_773078.host, call_773078.base,
                         call_773078.route, valid.getOrDefault("path"))
  result = hook(call_773078, url, valid)

proc call*(call_773149: Call_GetApis_772933; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var query_773150 = newJObject()
  add(query_773150, "maxResults", newJString(maxResults))
  add(query_773150, "nextToken", newJString(nextToken))
  result = call_773149.call(nil, query_773150, nil, nil, nil)

var getApis* = Call_GetApis_772933(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_772934,
                                base: "/", url: url_GetApis_772935,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_773235 = ref object of OpenApiRestCall_772597
proc url_CreateApiMapping_773237(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiMapping_773236(path: JsonNode; query: JsonNode;
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
  var valid_773238 = path.getOrDefault("domainName")
  valid_773238 = validateParameter(valid_773238, JString, required = true,
                                 default = nil)
  if valid_773238 != nil:
    section.add "domainName", valid_773238
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
  var valid_773239 = header.getOrDefault("X-Amz-Date")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Date", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Security-Token")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Security-Token", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Content-Sha256", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Algorithm")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Algorithm", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Signature")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Signature", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-SignedHeaders", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Credential")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Credential", valid_773245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773247: Call_CreateApiMapping_773235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_773247.validator(path, query, header, formData, body)
  let scheme = call_773247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773247.url(scheme.get, call_773247.host, call_773247.base,
                         call_773247.route, valid.getOrDefault("path"))
  result = hook(call_773247, url, valid)

proc call*(call_773248: Call_CreateApiMapping_773235; domainName: string;
          body: JsonNode): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_773249 = newJObject()
  var body_773250 = newJObject()
  add(path_773249, "domainName", newJString(domainName))
  if body != nil:
    body_773250 = body
  result = call_773248.call(path_773249, nil, nil, nil, body_773250)

var createApiMapping* = Call_CreateApiMapping_773235(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_773236, base: "/",
    url: url_CreateApiMapping_773237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_773204 = ref object of OpenApiRestCall_772597
proc url_GetApiMappings_773206(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMappings_773205(path: JsonNode; query: JsonNode;
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
  var valid_773221 = path.getOrDefault("domainName")
  valid_773221 = validateParameter(valid_773221, JString, required = true,
                                 default = nil)
  if valid_773221 != nil:
    section.add "domainName", valid_773221
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773222 = query.getOrDefault("maxResults")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "maxResults", valid_773222
  var valid_773223 = query.getOrDefault("nextToken")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "nextToken", valid_773223
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
  var valid_773224 = header.getOrDefault("X-Amz-Date")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Date", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Security-Token")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Security-Token", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Content-Sha256", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Algorithm")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Algorithm", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Signature")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Signature", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-SignedHeaders", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Credential")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Credential", valid_773230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773231: Call_GetApiMappings_773204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mappings.
  ## 
  let valid = call_773231.validator(path, query, header, formData, body)
  let scheme = call_773231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773231.url(scheme.get, call_773231.host, call_773231.base,
                         call_773231.route, valid.getOrDefault("path"))
  result = hook(call_773231, url, valid)

proc call*(call_773232: Call_GetApiMappings_773204; domainName: string;
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
  var path_773233 = newJObject()
  var query_773234 = newJObject()
  add(query_773234, "maxResults", newJString(maxResults))
  add(query_773234, "nextToken", newJString(nextToken))
  add(path_773233, "domainName", newJString(domainName))
  result = call_773232.call(path_773233, query_773234, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_773204(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_773205, base: "/", url: url_GetApiMappings_773206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_773268 = ref object of OpenApiRestCall_772597
proc url_CreateAuthorizer_773270(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_773269(path: JsonNode; query: JsonNode;
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
  var valid_773271 = path.getOrDefault("apiId")
  valid_773271 = validateParameter(valid_773271, JString, required = true,
                                 default = nil)
  if valid_773271 != nil:
    section.add "apiId", valid_773271
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
  var valid_773272 = header.getOrDefault("X-Amz-Date")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Date", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Security-Token")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Security-Token", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Content-Sha256", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Algorithm")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Algorithm", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Signature")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Signature", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-SignedHeaders", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Credential")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Credential", valid_773278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773280: Call_CreateAuthorizer_773268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_773280.validator(path, query, header, formData, body)
  let scheme = call_773280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773280.url(scheme.get, call_773280.host, call_773280.base,
                         call_773280.route, valid.getOrDefault("path"))
  result = hook(call_773280, url, valid)

proc call*(call_773281: Call_CreateAuthorizer_773268; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_773282 = newJObject()
  var body_773283 = newJObject()
  add(path_773282, "apiId", newJString(apiId))
  if body != nil:
    body_773283 = body
  result = call_773281.call(path_773282, nil, nil, nil, body_773283)

var createAuthorizer* = Call_CreateAuthorizer_773268(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_773269,
    base: "/", url: url_CreateAuthorizer_773270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_773251 = ref object of OpenApiRestCall_772597
proc url_GetAuthorizers_773253(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_773252(path: JsonNode; query: JsonNode;
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
  var valid_773254 = path.getOrDefault("apiId")
  valid_773254 = validateParameter(valid_773254, JString, required = true,
                                 default = nil)
  if valid_773254 != nil:
    section.add "apiId", valid_773254
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773255 = query.getOrDefault("maxResults")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "maxResults", valid_773255
  var valid_773256 = query.getOrDefault("nextToken")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "nextToken", valid_773256
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
  var valid_773257 = header.getOrDefault("X-Amz-Date")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Date", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Security-Token")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Security-Token", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Content-Sha256", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Algorithm")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Algorithm", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Signature")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Signature", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-SignedHeaders", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Credential")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Credential", valid_773263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773264: Call_GetAuthorizers_773251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_773264.validator(path, query, header, formData, body)
  let scheme = call_773264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773264.url(scheme.get, call_773264.host, call_773264.base,
                         call_773264.route, valid.getOrDefault("path"))
  result = hook(call_773264, url, valid)

proc call*(call_773265: Call_GetAuthorizers_773251; apiId: string;
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
  var path_773266 = newJObject()
  var query_773267 = newJObject()
  add(path_773266, "apiId", newJString(apiId))
  add(query_773267, "maxResults", newJString(maxResults))
  add(query_773267, "nextToken", newJString(nextToken))
  result = call_773265.call(path_773266, query_773267, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_773251(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_773252,
    base: "/", url: url_GetAuthorizers_773253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_773301 = ref object of OpenApiRestCall_772597
proc url_CreateDeployment_773303(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_773302(path: JsonNode; query: JsonNode;
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
  var valid_773304 = path.getOrDefault("apiId")
  valid_773304 = validateParameter(valid_773304, JString, required = true,
                                 default = nil)
  if valid_773304 != nil:
    section.add "apiId", valid_773304
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
  var valid_773305 = header.getOrDefault("X-Amz-Date")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Date", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Security-Token")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Security-Token", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Content-Sha256", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Algorithm")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Algorithm", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Signature")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Signature", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-SignedHeaders", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Credential")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Credential", valid_773311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773313: Call_CreateDeployment_773301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_773313.validator(path, query, header, formData, body)
  let scheme = call_773313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773313.url(scheme.get, call_773313.host, call_773313.base,
                         call_773313.route, valid.getOrDefault("path"))
  result = hook(call_773313, url, valid)

proc call*(call_773314: Call_CreateDeployment_773301; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_773315 = newJObject()
  var body_773316 = newJObject()
  add(path_773315, "apiId", newJString(apiId))
  if body != nil:
    body_773316 = body
  result = call_773314.call(path_773315, nil, nil, nil, body_773316)

var createDeployment* = Call_CreateDeployment_773301(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_773302,
    base: "/", url: url_CreateDeployment_773303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_773284 = ref object of OpenApiRestCall_772597
proc url_GetDeployments_773286(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_773285(path: JsonNode; query: JsonNode;
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
  var valid_773287 = path.getOrDefault("apiId")
  valid_773287 = validateParameter(valid_773287, JString, required = true,
                                 default = nil)
  if valid_773287 != nil:
    section.add "apiId", valid_773287
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773288 = query.getOrDefault("maxResults")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "maxResults", valid_773288
  var valid_773289 = query.getOrDefault("nextToken")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "nextToken", valid_773289
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
  var valid_773290 = header.getOrDefault("X-Amz-Date")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Date", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Security-Token")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Security-Token", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Content-Sha256", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Algorithm")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Algorithm", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Signature")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Signature", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-SignedHeaders", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Credential")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Credential", valid_773296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773297: Call_GetDeployments_773284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_773297.validator(path, query, header, formData, body)
  let scheme = call_773297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773297.url(scheme.get, call_773297.host, call_773297.base,
                         call_773297.route, valid.getOrDefault("path"))
  result = hook(call_773297, url, valid)

proc call*(call_773298: Call_GetDeployments_773284; apiId: string;
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
  var path_773299 = newJObject()
  var query_773300 = newJObject()
  add(path_773299, "apiId", newJString(apiId))
  add(query_773300, "maxResults", newJString(maxResults))
  add(query_773300, "nextToken", newJString(nextToken))
  result = call_773298.call(path_773299, query_773300, nil, nil, nil)

var getDeployments* = Call_GetDeployments_773284(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_773285,
    base: "/", url: url_GetDeployments_773286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_773332 = ref object of OpenApiRestCall_772597
proc url_CreateDomainName_773334(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDomainName_773333(path: JsonNode; query: JsonNode;
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
  var valid_773335 = header.getOrDefault("X-Amz-Date")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Date", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Security-Token")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Security-Token", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Content-Sha256", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Algorithm")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Algorithm", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Signature")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Signature", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-SignedHeaders", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Credential")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Credential", valid_773341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773343: Call_CreateDomainName_773332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_773343.validator(path, query, header, formData, body)
  let scheme = call_773343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773343.url(scheme.get, call_773343.host, call_773343.base,
                         call_773343.route, valid.getOrDefault("path"))
  result = hook(call_773343, url, valid)

proc call*(call_773344: Call_CreateDomainName_773332; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_773345 = newJObject()
  if body != nil:
    body_773345 = body
  result = call_773344.call(nil, nil, nil, nil, body_773345)

var createDomainName* = Call_CreateDomainName_773332(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_773333,
    base: "/", url: url_CreateDomainName_773334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_773317 = ref object of OpenApiRestCall_772597
proc url_GetDomainNames_773319(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainNames_773318(path: JsonNode; query: JsonNode;
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
  var valid_773320 = query.getOrDefault("maxResults")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "maxResults", valid_773320
  var valid_773321 = query.getOrDefault("nextToken")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "nextToken", valid_773321
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
  var valid_773322 = header.getOrDefault("X-Amz-Date")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Date", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Security-Token")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Security-Token", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Content-Sha256", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Algorithm")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Algorithm", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Signature")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Signature", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-SignedHeaders", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Credential")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Credential", valid_773328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773329: Call_GetDomainNames_773317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_773329.validator(path, query, header, formData, body)
  let scheme = call_773329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773329.url(scheme.get, call_773329.host, call_773329.base,
                         call_773329.route, valid.getOrDefault("path"))
  result = hook(call_773329, url, valid)

proc call*(call_773330: Call_GetDomainNames_773317; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var query_773331 = newJObject()
  add(query_773331, "maxResults", newJString(maxResults))
  add(query_773331, "nextToken", newJString(nextToken))
  result = call_773330.call(nil, query_773331, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_773317(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_773318, base: "/",
    url: url_GetDomainNames_773319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_773363 = ref object of OpenApiRestCall_772597
proc url_CreateIntegration_773365(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIntegration_773364(path: JsonNode; query: JsonNode;
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
  var valid_773366 = path.getOrDefault("apiId")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = nil)
  if valid_773366 != nil:
    section.add "apiId", valid_773366
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
  var valid_773367 = header.getOrDefault("X-Amz-Date")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Date", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Security-Token")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Security-Token", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Content-Sha256", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Algorithm")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Algorithm", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Signature")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Signature", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-SignedHeaders", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Credential")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Credential", valid_773373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773375: Call_CreateIntegration_773363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_773375.validator(path, query, header, formData, body)
  let scheme = call_773375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773375.url(scheme.get, call_773375.host, call_773375.base,
                         call_773375.route, valid.getOrDefault("path"))
  result = hook(call_773375, url, valid)

proc call*(call_773376: Call_CreateIntegration_773363; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_773377 = newJObject()
  var body_773378 = newJObject()
  add(path_773377, "apiId", newJString(apiId))
  if body != nil:
    body_773378 = body
  result = call_773376.call(path_773377, nil, nil, nil, body_773378)

var createIntegration* = Call_CreateIntegration_773363(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_773364,
    base: "/", url: url_CreateIntegration_773365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_773346 = ref object of OpenApiRestCall_772597
proc url_GetIntegrations_773348(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrations_773347(path: JsonNode; query: JsonNode;
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
  var valid_773349 = path.getOrDefault("apiId")
  valid_773349 = validateParameter(valid_773349, JString, required = true,
                                 default = nil)
  if valid_773349 != nil:
    section.add "apiId", valid_773349
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773350 = query.getOrDefault("maxResults")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "maxResults", valid_773350
  var valid_773351 = query.getOrDefault("nextToken")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "nextToken", valid_773351
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
  var valid_773352 = header.getOrDefault("X-Amz-Date")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Date", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Security-Token")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Security-Token", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Content-Sha256", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Algorithm")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Algorithm", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Signature")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Signature", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-SignedHeaders", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Credential")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Credential", valid_773358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773359: Call_GetIntegrations_773346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_773359.validator(path, query, header, formData, body)
  let scheme = call_773359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773359.url(scheme.get, call_773359.host, call_773359.base,
                         call_773359.route, valid.getOrDefault("path"))
  result = hook(call_773359, url, valid)

proc call*(call_773360: Call_GetIntegrations_773346; apiId: string;
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
  var path_773361 = newJObject()
  var query_773362 = newJObject()
  add(path_773361, "apiId", newJString(apiId))
  add(query_773362, "maxResults", newJString(maxResults))
  add(query_773362, "nextToken", newJString(nextToken))
  result = call_773360.call(path_773361, query_773362, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_773346(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_773347,
    base: "/", url: url_GetIntegrations_773348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_773397 = ref object of OpenApiRestCall_772597
proc url_CreateIntegrationResponse_773399(protocol: Scheme; host: string;
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

proc validate_CreateIntegrationResponse_773398(path: JsonNode; query: JsonNode;
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
  var valid_773400 = path.getOrDefault("apiId")
  valid_773400 = validateParameter(valid_773400, JString, required = true,
                                 default = nil)
  if valid_773400 != nil:
    section.add "apiId", valid_773400
  var valid_773401 = path.getOrDefault("integrationId")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = nil)
  if valid_773401 != nil:
    section.add "integrationId", valid_773401
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
  var valid_773402 = header.getOrDefault("X-Amz-Date")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Date", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Security-Token")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Security-Token", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Content-Sha256", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Algorithm")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Algorithm", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Signature")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Signature", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-SignedHeaders", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Credential")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Credential", valid_773408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773410: Call_CreateIntegrationResponse_773397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_773410.validator(path, query, header, formData, body)
  let scheme = call_773410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773410.url(scheme.get, call_773410.host, call_773410.base,
                         call_773410.route, valid.getOrDefault("path"))
  result = hook(call_773410, url, valid)

proc call*(call_773411: Call_CreateIntegrationResponse_773397; apiId: string;
          body: JsonNode; integrationId: string): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_773412 = newJObject()
  var body_773413 = newJObject()
  add(path_773412, "apiId", newJString(apiId))
  if body != nil:
    body_773413 = body
  add(path_773412, "integrationId", newJString(integrationId))
  result = call_773411.call(path_773412, nil, nil, nil, body_773413)

var createIntegrationResponse* = Call_CreateIntegrationResponse_773397(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_773398, base: "/",
    url: url_CreateIntegrationResponse_773399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_773379 = ref object of OpenApiRestCall_772597
proc url_GetIntegrationResponses_773381(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponses_773380(path: JsonNode; query: JsonNode;
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
  var valid_773382 = path.getOrDefault("apiId")
  valid_773382 = validateParameter(valid_773382, JString, required = true,
                                 default = nil)
  if valid_773382 != nil:
    section.add "apiId", valid_773382
  var valid_773383 = path.getOrDefault("integrationId")
  valid_773383 = validateParameter(valid_773383, JString, required = true,
                                 default = nil)
  if valid_773383 != nil:
    section.add "integrationId", valid_773383
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773384 = query.getOrDefault("maxResults")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "maxResults", valid_773384
  var valid_773385 = query.getOrDefault("nextToken")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "nextToken", valid_773385
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
  var valid_773386 = header.getOrDefault("X-Amz-Date")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Date", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Security-Token")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Security-Token", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773393: Call_GetIntegrationResponses_773379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_773393.validator(path, query, header, formData, body)
  let scheme = call_773393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773393.url(scheme.get, call_773393.host, call_773393.base,
                         call_773393.route, valid.getOrDefault("path"))
  result = hook(call_773393, url, valid)

proc call*(call_773394: Call_GetIntegrationResponses_773379; apiId: string;
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
  var path_773395 = newJObject()
  var query_773396 = newJObject()
  add(path_773395, "apiId", newJString(apiId))
  add(query_773396, "maxResults", newJString(maxResults))
  add(query_773396, "nextToken", newJString(nextToken))
  add(path_773395, "integrationId", newJString(integrationId))
  result = call_773394.call(path_773395, query_773396, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_773379(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_773380, base: "/",
    url: url_GetIntegrationResponses_773381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_773431 = ref object of OpenApiRestCall_772597
proc url_CreateModel_773433(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_773432(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773434 = path.getOrDefault("apiId")
  valid_773434 = validateParameter(valid_773434, JString, required = true,
                                 default = nil)
  if valid_773434 != nil:
    section.add "apiId", valid_773434
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
  var valid_773435 = header.getOrDefault("X-Amz-Date")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Date", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Security-Token")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Security-Token", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Content-Sha256", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Algorithm")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Algorithm", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Signature")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Signature", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-SignedHeaders", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Credential")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Credential", valid_773441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773443: Call_CreateModel_773431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_773443.validator(path, query, header, formData, body)
  let scheme = call_773443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773443.url(scheme.get, call_773443.host, call_773443.base,
                         call_773443.route, valid.getOrDefault("path"))
  result = hook(call_773443, url, valid)

proc call*(call_773444: Call_CreateModel_773431; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_773445 = newJObject()
  var body_773446 = newJObject()
  add(path_773445, "apiId", newJString(apiId))
  if body != nil:
    body_773446 = body
  result = call_773444.call(path_773445, nil, nil, nil, body_773446)

var createModel* = Call_CreateModel_773431(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_773432,
                                        base: "/", url: url_CreateModel_773433,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_773414 = ref object of OpenApiRestCall_772597
proc url_GetModels_773416(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_773415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773417 = path.getOrDefault("apiId")
  valid_773417 = validateParameter(valid_773417, JString, required = true,
                                 default = nil)
  if valid_773417 != nil:
    section.add "apiId", valid_773417
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773418 = query.getOrDefault("maxResults")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "maxResults", valid_773418
  var valid_773419 = query.getOrDefault("nextToken")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "nextToken", valid_773419
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
  var valid_773420 = header.getOrDefault("X-Amz-Date")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Date", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Security-Token")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Security-Token", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Content-Sha256", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Algorithm")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Algorithm", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Signature")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Signature", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-SignedHeaders", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Credential")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Credential", valid_773426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773427: Call_GetModels_773414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_773427.validator(path, query, header, formData, body)
  let scheme = call_773427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773427.url(scheme.get, call_773427.host, call_773427.base,
                         call_773427.route, valid.getOrDefault("path"))
  result = hook(call_773427, url, valid)

proc call*(call_773428: Call_GetModels_773414; apiId: string;
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
  var path_773429 = newJObject()
  var query_773430 = newJObject()
  add(path_773429, "apiId", newJString(apiId))
  add(query_773430, "maxResults", newJString(maxResults))
  add(query_773430, "nextToken", newJString(nextToken))
  result = call_773428.call(path_773429, query_773430, nil, nil, nil)

var getModels* = Call_GetModels_773414(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_773415,
                                    base: "/", url: url_GetModels_773416,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_773464 = ref object of OpenApiRestCall_772597
proc url_CreateRoute_773466(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_773465(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773467 = path.getOrDefault("apiId")
  valid_773467 = validateParameter(valid_773467, JString, required = true,
                                 default = nil)
  if valid_773467 != nil:
    section.add "apiId", valid_773467
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
  var valid_773468 = header.getOrDefault("X-Amz-Date")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Date", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Security-Token")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Security-Token", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Content-Sha256", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Algorithm")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Algorithm", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Signature")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Signature", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-SignedHeaders", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Credential")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Credential", valid_773474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773476: Call_CreateRoute_773464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_773476.validator(path, query, header, formData, body)
  let scheme = call_773476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773476.url(scheme.get, call_773476.host, call_773476.base,
                         call_773476.route, valid.getOrDefault("path"))
  result = hook(call_773476, url, valid)

proc call*(call_773477: Call_CreateRoute_773464; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_773478 = newJObject()
  var body_773479 = newJObject()
  add(path_773478, "apiId", newJString(apiId))
  if body != nil:
    body_773479 = body
  result = call_773477.call(path_773478, nil, nil, nil, body_773479)

var createRoute* = Call_CreateRoute_773464(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_773465,
                                        base: "/", url: url_CreateRoute_773466,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_773447 = ref object of OpenApiRestCall_772597
proc url_GetRoutes_773449(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoutes_773448(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773450 = path.getOrDefault("apiId")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = nil)
  if valid_773450 != nil:
    section.add "apiId", valid_773450
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773451 = query.getOrDefault("maxResults")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "maxResults", valid_773451
  var valid_773452 = query.getOrDefault("nextToken")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "nextToken", valid_773452
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
  var valid_773453 = header.getOrDefault("X-Amz-Date")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Date", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Security-Token")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Security-Token", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Content-Sha256", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Algorithm")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Algorithm", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Signature")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Signature", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-SignedHeaders", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Credential")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Credential", valid_773459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773460: Call_GetRoutes_773447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_773460.validator(path, query, header, formData, body)
  let scheme = call_773460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773460.url(scheme.get, call_773460.host, call_773460.base,
                         call_773460.route, valid.getOrDefault("path"))
  result = hook(call_773460, url, valid)

proc call*(call_773461: Call_GetRoutes_773447; apiId: string;
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
  var path_773462 = newJObject()
  var query_773463 = newJObject()
  add(path_773462, "apiId", newJString(apiId))
  add(query_773463, "maxResults", newJString(maxResults))
  add(query_773463, "nextToken", newJString(nextToken))
  result = call_773461.call(path_773462, query_773463, nil, nil, nil)

var getRoutes* = Call_GetRoutes_773447(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_773448,
                                    base: "/", url: url_GetRoutes_773449,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_773498 = ref object of OpenApiRestCall_772597
proc url_CreateRouteResponse_773500(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRouteResponse_773499(path: JsonNode; query: JsonNode;
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
  var valid_773501 = path.getOrDefault("apiId")
  valid_773501 = validateParameter(valid_773501, JString, required = true,
                                 default = nil)
  if valid_773501 != nil:
    section.add "apiId", valid_773501
  var valid_773502 = path.getOrDefault("routeId")
  valid_773502 = validateParameter(valid_773502, JString, required = true,
                                 default = nil)
  if valid_773502 != nil:
    section.add "routeId", valid_773502
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
  var valid_773503 = header.getOrDefault("X-Amz-Date")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Date", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Security-Token")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Security-Token", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Content-Sha256", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Algorithm")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Algorithm", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Signature")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Signature", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-SignedHeaders", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Credential")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Credential", valid_773509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773511: Call_CreateRouteResponse_773498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_773511.validator(path, query, header, formData, body)
  let scheme = call_773511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773511.url(scheme.get, call_773511.host, call_773511.base,
                         call_773511.route, valid.getOrDefault("path"))
  result = hook(call_773511, url, valid)

proc call*(call_773512: Call_CreateRouteResponse_773498; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_773513 = newJObject()
  var body_773514 = newJObject()
  add(path_773513, "apiId", newJString(apiId))
  if body != nil:
    body_773514 = body
  add(path_773513, "routeId", newJString(routeId))
  result = call_773512.call(path_773513, nil, nil, nil, body_773514)

var createRouteResponse* = Call_CreateRouteResponse_773498(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_773499, base: "/",
    url: url_CreateRouteResponse_773500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_773480 = ref object of OpenApiRestCall_772597
proc url_GetRouteResponses_773482(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponses_773481(path: JsonNode; query: JsonNode;
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
  var valid_773483 = path.getOrDefault("apiId")
  valid_773483 = validateParameter(valid_773483, JString, required = true,
                                 default = nil)
  if valid_773483 != nil:
    section.add "apiId", valid_773483
  var valid_773484 = path.getOrDefault("routeId")
  valid_773484 = validateParameter(valid_773484, JString, required = true,
                                 default = nil)
  if valid_773484 != nil:
    section.add "routeId", valid_773484
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773485 = query.getOrDefault("maxResults")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "maxResults", valid_773485
  var valid_773486 = query.getOrDefault("nextToken")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "nextToken", valid_773486
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
  var valid_773487 = header.getOrDefault("X-Amz-Date")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Date", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Security-Token")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Security-Token", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Content-Sha256", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Algorithm")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Algorithm", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Signature")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Signature", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-SignedHeaders", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Credential")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Credential", valid_773493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773494: Call_GetRouteResponses_773480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_773494.validator(path, query, header, formData, body)
  let scheme = call_773494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773494.url(scheme.get, call_773494.host, call_773494.base,
                         call_773494.route, valid.getOrDefault("path"))
  result = hook(call_773494, url, valid)

proc call*(call_773495: Call_GetRouteResponses_773480; apiId: string;
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
  var path_773496 = newJObject()
  var query_773497 = newJObject()
  add(path_773496, "apiId", newJString(apiId))
  add(query_773497, "maxResults", newJString(maxResults))
  add(query_773497, "nextToken", newJString(nextToken))
  add(path_773496, "routeId", newJString(routeId))
  result = call_773495.call(path_773496, query_773497, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_773480(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_773481, base: "/",
    url: url_GetRouteResponses_773482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_773532 = ref object of OpenApiRestCall_772597
proc url_CreateStage_773534(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_773533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773535 = path.getOrDefault("apiId")
  valid_773535 = validateParameter(valid_773535, JString, required = true,
                                 default = nil)
  if valid_773535 != nil:
    section.add "apiId", valid_773535
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
  var valid_773536 = header.getOrDefault("X-Amz-Date")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Date", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Security-Token")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Security-Token", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Content-Sha256", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Algorithm")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Algorithm", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Signature")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Signature", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-SignedHeaders", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Credential")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Credential", valid_773542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773544: Call_CreateStage_773532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_773544.validator(path, query, header, formData, body)
  let scheme = call_773544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773544.url(scheme.get, call_773544.host, call_773544.base,
                         call_773544.route, valid.getOrDefault("path"))
  result = hook(call_773544, url, valid)

proc call*(call_773545: Call_CreateStage_773532; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_773546 = newJObject()
  var body_773547 = newJObject()
  add(path_773546, "apiId", newJString(apiId))
  if body != nil:
    body_773547 = body
  result = call_773545.call(path_773546, nil, nil, nil, body_773547)

var createStage* = Call_CreateStage_773532(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_773533,
                                        base: "/", url: url_CreateStage_773534,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_773515 = ref object of OpenApiRestCall_772597
proc url_GetStages_773517(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_773516(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773518 = path.getOrDefault("apiId")
  valid_773518 = validateParameter(valid_773518, JString, required = true,
                                 default = nil)
  if valid_773518 != nil:
    section.add "apiId", valid_773518
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_773519 = query.getOrDefault("maxResults")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "maxResults", valid_773519
  var valid_773520 = query.getOrDefault("nextToken")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "nextToken", valid_773520
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
  var valid_773521 = header.getOrDefault("X-Amz-Date")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Date", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Security-Token")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Security-Token", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Content-Sha256", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Algorithm")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Algorithm", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Signature")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Signature", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-SignedHeaders", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Credential")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Credential", valid_773527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773528: Call_GetStages_773515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_773528.validator(path, query, header, formData, body)
  let scheme = call_773528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773528.url(scheme.get, call_773528.host, call_773528.base,
                         call_773528.route, valid.getOrDefault("path"))
  result = hook(call_773528, url, valid)

proc call*(call_773529: Call_GetStages_773515; apiId: string;
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
  var path_773530 = newJObject()
  var query_773531 = newJObject()
  add(path_773530, "apiId", newJString(apiId))
  add(query_773531, "maxResults", newJString(maxResults))
  add(query_773531, "nextToken", newJString(nextToken))
  result = call_773529.call(path_773530, query_773531, nil, nil, nil)

var getStages* = Call_GetStages_773515(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_773516,
                                    base: "/", url: url_GetStages_773517,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_773548 = ref object of OpenApiRestCall_772597
proc url_GetApi_773550(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApi_773549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773551 = path.getOrDefault("apiId")
  valid_773551 = validateParameter(valid_773551, JString, required = true,
                                 default = nil)
  if valid_773551 != nil:
    section.add "apiId", valid_773551
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
  var valid_773552 = header.getOrDefault("X-Amz-Date")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Date", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Security-Token")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Security-Token", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Content-Sha256", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Algorithm")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Algorithm", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Signature")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Signature", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-SignedHeaders", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Credential")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Credential", valid_773558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773559: Call_GetApi_773548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_773559.validator(path, query, header, formData, body)
  let scheme = call_773559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773559.url(scheme.get, call_773559.host, call_773559.base,
                         call_773559.route, valid.getOrDefault("path"))
  result = hook(call_773559, url, valid)

proc call*(call_773560: Call_GetApi_773548; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_773561 = newJObject()
  add(path_773561, "apiId", newJString(apiId))
  result = call_773560.call(path_773561, nil, nil, nil, nil)

var getApi* = Call_GetApi_773548(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_773549, base: "/",
                              url: url_GetApi_773550,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_773576 = ref object of OpenApiRestCall_772597
proc url_UpdateApi_773578(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApi_773577(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773579 = path.getOrDefault("apiId")
  valid_773579 = validateParameter(valid_773579, JString, required = true,
                                 default = nil)
  if valid_773579 != nil:
    section.add "apiId", valid_773579
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
  var valid_773580 = header.getOrDefault("X-Amz-Date")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Date", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Security-Token")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Security-Token", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Content-Sha256", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Algorithm")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Algorithm", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Signature")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Signature", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-SignedHeaders", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Credential")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Credential", valid_773586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773588: Call_UpdateApi_773576; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_773588.validator(path, query, header, formData, body)
  let scheme = call_773588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773588.url(scheme.get, call_773588.host, call_773588.base,
                         call_773588.route, valid.getOrDefault("path"))
  result = hook(call_773588, url, valid)

proc call*(call_773589: Call_UpdateApi_773576; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_773590 = newJObject()
  var body_773591 = newJObject()
  add(path_773590, "apiId", newJString(apiId))
  if body != nil:
    body_773591 = body
  result = call_773589.call(path_773590, nil, nil, nil, body_773591)

var updateApi* = Call_UpdateApi_773576(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_773577,
                                    base: "/", url: url_UpdateApi_773578,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_773562 = ref object of OpenApiRestCall_772597
proc url_DeleteApi_773564(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApi_773563(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773565 = path.getOrDefault("apiId")
  valid_773565 = validateParameter(valid_773565, JString, required = true,
                                 default = nil)
  if valid_773565 != nil:
    section.add "apiId", valid_773565
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
  var valid_773566 = header.getOrDefault("X-Amz-Date")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Date", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Security-Token")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Security-Token", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Content-Sha256", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Algorithm")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Algorithm", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Signature")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Signature", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-SignedHeaders", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Credential")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Credential", valid_773572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773573: Call_DeleteApi_773562; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_773573.validator(path, query, header, formData, body)
  let scheme = call_773573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773573.url(scheme.get, call_773573.host, call_773573.base,
                         call_773573.route, valid.getOrDefault("path"))
  result = hook(call_773573, url, valid)

proc call*(call_773574: Call_DeleteApi_773562; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_773575 = newJObject()
  add(path_773575, "apiId", newJString(apiId))
  result = call_773574.call(path_773575, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_773562(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_773563,
                                    base: "/", url: url_DeleteApi_773564,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_773592 = ref object of OpenApiRestCall_772597
proc url_GetApiMapping_773594(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMapping_773593(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773595 = path.getOrDefault("domainName")
  valid_773595 = validateParameter(valid_773595, JString, required = true,
                                 default = nil)
  if valid_773595 != nil:
    section.add "domainName", valid_773595
  var valid_773596 = path.getOrDefault("apiMappingId")
  valid_773596 = validateParameter(valid_773596, JString, required = true,
                                 default = nil)
  if valid_773596 != nil:
    section.add "apiMappingId", valid_773596
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
  var valid_773597 = header.getOrDefault("X-Amz-Date")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Date", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Security-Token")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Security-Token", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Content-Sha256", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Algorithm")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Algorithm", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Signature")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Signature", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-SignedHeaders", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Credential")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Credential", valid_773603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773604: Call_GetApiMapping_773592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_773604.validator(path, query, header, formData, body)
  let scheme = call_773604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773604.url(scheme.get, call_773604.host, call_773604.base,
                         call_773604.route, valid.getOrDefault("path"))
  result = hook(call_773604, url, valid)

proc call*(call_773605: Call_GetApiMapping_773592; domainName: string;
          apiMappingId: string): Recallable =
  ## getApiMapping
  ## The API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_773606 = newJObject()
  add(path_773606, "domainName", newJString(domainName))
  add(path_773606, "apiMappingId", newJString(apiMappingId))
  result = call_773605.call(path_773606, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_773592(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_773593, base: "/", url: url_GetApiMapping_773594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_773622 = ref object of OpenApiRestCall_772597
proc url_UpdateApiMapping_773624(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiMapping_773623(path: JsonNode; query: JsonNode;
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
  var valid_773625 = path.getOrDefault("domainName")
  valid_773625 = validateParameter(valid_773625, JString, required = true,
                                 default = nil)
  if valid_773625 != nil:
    section.add "domainName", valid_773625
  var valid_773626 = path.getOrDefault("apiMappingId")
  valid_773626 = validateParameter(valid_773626, JString, required = true,
                                 default = nil)
  if valid_773626 != nil:
    section.add "apiMappingId", valid_773626
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
  var valid_773627 = header.getOrDefault("X-Amz-Date")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Date", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Security-Token")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Security-Token", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Content-Sha256", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Algorithm")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Algorithm", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-Signature")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Signature", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-SignedHeaders", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Credential")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Credential", valid_773633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773635: Call_UpdateApiMapping_773622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_773635.validator(path, query, header, formData, body)
  let scheme = call_773635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773635.url(scheme.get, call_773635.host, call_773635.base,
                         call_773635.route, valid.getOrDefault("path"))
  result = hook(call_773635, url, valid)

proc call*(call_773636: Call_UpdateApiMapping_773622; domainName: string;
          apiMappingId: string; body: JsonNode): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  var path_773637 = newJObject()
  var body_773638 = newJObject()
  add(path_773637, "domainName", newJString(domainName))
  add(path_773637, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_773638 = body
  result = call_773636.call(path_773637, nil, nil, nil, body_773638)

var updateApiMapping* = Call_UpdateApiMapping_773622(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_773623, base: "/",
    url: url_UpdateApiMapping_773624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_773607 = ref object of OpenApiRestCall_772597
proc url_DeleteApiMapping_773609(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiMapping_773608(path: JsonNode; query: JsonNode;
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
  var valid_773610 = path.getOrDefault("domainName")
  valid_773610 = validateParameter(valid_773610, JString, required = true,
                                 default = nil)
  if valid_773610 != nil:
    section.add "domainName", valid_773610
  var valid_773611 = path.getOrDefault("apiMappingId")
  valid_773611 = validateParameter(valid_773611, JString, required = true,
                                 default = nil)
  if valid_773611 != nil:
    section.add "apiMappingId", valid_773611
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
  var valid_773612 = header.getOrDefault("X-Amz-Date")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Date", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Security-Token")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Security-Token", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Content-Sha256", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Algorithm")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Algorithm", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Signature")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Signature", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-SignedHeaders", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Credential")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Credential", valid_773618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773619: Call_DeleteApiMapping_773607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_773619.validator(path, query, header, formData, body)
  let scheme = call_773619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773619.url(scheme.get, call_773619.host, call_773619.base,
                         call_773619.route, valid.getOrDefault("path"))
  result = hook(call_773619, url, valid)

proc call*(call_773620: Call_DeleteApiMapping_773607; domainName: string;
          apiMappingId: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_773621 = newJObject()
  add(path_773621, "domainName", newJString(domainName))
  add(path_773621, "apiMappingId", newJString(apiMappingId))
  result = call_773620.call(path_773621, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_773607(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_773608, base: "/",
    url: url_DeleteApiMapping_773609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_773639 = ref object of OpenApiRestCall_772597
proc url_GetAuthorizer_773641(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_773640(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773642 = path.getOrDefault("apiId")
  valid_773642 = validateParameter(valid_773642, JString, required = true,
                                 default = nil)
  if valid_773642 != nil:
    section.add "apiId", valid_773642
  var valid_773643 = path.getOrDefault("authorizerId")
  valid_773643 = validateParameter(valid_773643, JString, required = true,
                                 default = nil)
  if valid_773643 != nil:
    section.add "authorizerId", valid_773643
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
  var valid_773644 = header.getOrDefault("X-Amz-Date")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Date", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Security-Token")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Security-Token", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Content-Sha256", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Algorithm")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Algorithm", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Signature")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Signature", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-SignedHeaders", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Credential")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Credential", valid_773650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773651: Call_GetAuthorizer_773639; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_773651.validator(path, query, header, formData, body)
  let scheme = call_773651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773651.url(scheme.get, call_773651.host, call_773651.base,
                         call_773651.route, valid.getOrDefault("path"))
  result = hook(call_773651, url, valid)

proc call*(call_773652: Call_GetAuthorizer_773639; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_773653 = newJObject()
  add(path_773653, "apiId", newJString(apiId))
  add(path_773653, "authorizerId", newJString(authorizerId))
  result = call_773652.call(path_773653, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_773639(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_773640, base: "/", url: url_GetAuthorizer_773641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_773669 = ref object of OpenApiRestCall_772597
proc url_UpdateAuthorizer_773671(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_773670(path: JsonNode; query: JsonNode;
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
  var valid_773672 = path.getOrDefault("apiId")
  valid_773672 = validateParameter(valid_773672, JString, required = true,
                                 default = nil)
  if valid_773672 != nil:
    section.add "apiId", valid_773672
  var valid_773673 = path.getOrDefault("authorizerId")
  valid_773673 = validateParameter(valid_773673, JString, required = true,
                                 default = nil)
  if valid_773673 != nil:
    section.add "authorizerId", valid_773673
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
  var valid_773674 = header.getOrDefault("X-Amz-Date")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Date", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Security-Token")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Security-Token", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Content-Sha256", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Algorithm")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Algorithm", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Signature")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Signature", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-SignedHeaders", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Credential")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Credential", valid_773680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773682: Call_UpdateAuthorizer_773669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_773682.validator(path, query, header, formData, body)
  let scheme = call_773682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773682.url(scheme.get, call_773682.host, call_773682.base,
                         call_773682.route, valid.getOrDefault("path"))
  result = hook(call_773682, url, valid)

proc call*(call_773683: Call_UpdateAuthorizer_773669; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_773684 = newJObject()
  var body_773685 = newJObject()
  add(path_773684, "apiId", newJString(apiId))
  add(path_773684, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_773685 = body
  result = call_773683.call(path_773684, nil, nil, nil, body_773685)

var updateAuthorizer* = Call_UpdateAuthorizer_773669(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_773670, base: "/",
    url: url_UpdateAuthorizer_773671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_773654 = ref object of OpenApiRestCall_772597
proc url_DeleteAuthorizer_773656(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_773655(path: JsonNode; query: JsonNode;
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
  var valid_773657 = path.getOrDefault("apiId")
  valid_773657 = validateParameter(valid_773657, JString, required = true,
                                 default = nil)
  if valid_773657 != nil:
    section.add "apiId", valid_773657
  var valid_773658 = path.getOrDefault("authorizerId")
  valid_773658 = validateParameter(valid_773658, JString, required = true,
                                 default = nil)
  if valid_773658 != nil:
    section.add "authorizerId", valid_773658
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
  var valid_773659 = header.getOrDefault("X-Amz-Date")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Date", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Security-Token")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Security-Token", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Content-Sha256", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Algorithm")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Algorithm", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Signature")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Signature", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-SignedHeaders", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Credential")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Credential", valid_773665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773666: Call_DeleteAuthorizer_773654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_773666.validator(path, query, header, formData, body)
  let scheme = call_773666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773666.url(scheme.get, call_773666.host, call_773666.base,
                         call_773666.route, valid.getOrDefault("path"))
  result = hook(call_773666, url, valid)

proc call*(call_773667: Call_DeleteAuthorizer_773654; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_773668 = newJObject()
  add(path_773668, "apiId", newJString(apiId))
  add(path_773668, "authorizerId", newJString(authorizerId))
  result = call_773667.call(path_773668, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_773654(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_773655, base: "/",
    url: url_DeleteAuthorizer_773656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_773686 = ref object of OpenApiRestCall_772597
proc url_GetDeployment_773688(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_773687(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773689 = path.getOrDefault("apiId")
  valid_773689 = validateParameter(valid_773689, JString, required = true,
                                 default = nil)
  if valid_773689 != nil:
    section.add "apiId", valid_773689
  var valid_773690 = path.getOrDefault("deploymentId")
  valid_773690 = validateParameter(valid_773690, JString, required = true,
                                 default = nil)
  if valid_773690 != nil:
    section.add "deploymentId", valid_773690
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
  var valid_773691 = header.getOrDefault("X-Amz-Date")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Date", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Security-Token")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Security-Token", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Content-Sha256", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Algorithm")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Algorithm", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Signature")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Signature", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-SignedHeaders", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Credential")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Credential", valid_773697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773698: Call_GetDeployment_773686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_773698.validator(path, query, header, formData, body)
  let scheme = call_773698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773698.url(scheme.get, call_773698.host, call_773698.base,
                         call_773698.route, valid.getOrDefault("path"))
  result = hook(call_773698, url, valid)

proc call*(call_773699: Call_GetDeployment_773686; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_773700 = newJObject()
  add(path_773700, "apiId", newJString(apiId))
  add(path_773700, "deploymentId", newJString(deploymentId))
  result = call_773699.call(path_773700, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_773686(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_773687, base: "/", url: url_GetDeployment_773688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_773716 = ref object of OpenApiRestCall_772597
proc url_UpdateDeployment_773718(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_773717(path: JsonNode; query: JsonNode;
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
  var valid_773719 = path.getOrDefault("apiId")
  valid_773719 = validateParameter(valid_773719, JString, required = true,
                                 default = nil)
  if valid_773719 != nil:
    section.add "apiId", valid_773719
  var valid_773720 = path.getOrDefault("deploymentId")
  valid_773720 = validateParameter(valid_773720, JString, required = true,
                                 default = nil)
  if valid_773720 != nil:
    section.add "deploymentId", valid_773720
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
  var valid_773721 = header.getOrDefault("X-Amz-Date")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-Date", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Security-Token")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Security-Token", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Content-Sha256", valid_773723
  var valid_773724 = header.getOrDefault("X-Amz-Algorithm")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Algorithm", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Signature")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Signature", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-SignedHeaders", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Credential")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Credential", valid_773727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773729: Call_UpdateDeployment_773716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_773729.validator(path, query, header, formData, body)
  let scheme = call_773729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773729.url(scheme.get, call_773729.host, call_773729.base,
                         call_773729.route, valid.getOrDefault("path"))
  result = hook(call_773729, url, valid)

proc call*(call_773730: Call_UpdateDeployment_773716; apiId: string;
          deploymentId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  ##   body: JObject (required)
  var path_773731 = newJObject()
  var body_773732 = newJObject()
  add(path_773731, "apiId", newJString(apiId))
  add(path_773731, "deploymentId", newJString(deploymentId))
  if body != nil:
    body_773732 = body
  result = call_773730.call(path_773731, nil, nil, nil, body_773732)

var updateDeployment* = Call_UpdateDeployment_773716(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_773717, base: "/",
    url: url_UpdateDeployment_773718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_773701 = ref object of OpenApiRestCall_772597
proc url_DeleteDeployment_773703(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_773702(path: JsonNode; query: JsonNode;
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
  var valid_773704 = path.getOrDefault("apiId")
  valid_773704 = validateParameter(valid_773704, JString, required = true,
                                 default = nil)
  if valid_773704 != nil:
    section.add "apiId", valid_773704
  var valid_773705 = path.getOrDefault("deploymentId")
  valid_773705 = validateParameter(valid_773705, JString, required = true,
                                 default = nil)
  if valid_773705 != nil:
    section.add "deploymentId", valid_773705
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
  var valid_773706 = header.getOrDefault("X-Amz-Date")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Date", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Security-Token")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Security-Token", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Content-Sha256", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-Algorithm")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Algorithm", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Signature")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Signature", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-SignedHeaders", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Credential")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Credential", valid_773712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773713: Call_DeleteDeployment_773701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_773713.validator(path, query, header, formData, body)
  let scheme = call_773713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773713.url(scheme.get, call_773713.host, call_773713.base,
                         call_773713.route, valid.getOrDefault("path"))
  result = hook(call_773713, url, valid)

proc call*(call_773714: Call_DeleteDeployment_773701; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_773715 = newJObject()
  add(path_773715, "apiId", newJString(apiId))
  add(path_773715, "deploymentId", newJString(deploymentId))
  result = call_773714.call(path_773715, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_773701(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_773702, base: "/",
    url: url_DeleteDeployment_773703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_773733 = ref object of OpenApiRestCall_772597
proc url_GetDomainName_773735(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_773734(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773736 = path.getOrDefault("domainName")
  valid_773736 = validateParameter(valid_773736, JString, required = true,
                                 default = nil)
  if valid_773736 != nil:
    section.add "domainName", valid_773736
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
  var valid_773737 = header.getOrDefault("X-Amz-Date")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Date", valid_773737
  var valid_773738 = header.getOrDefault("X-Amz-Security-Token")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Security-Token", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Content-Sha256", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-Algorithm")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Algorithm", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Signature")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Signature", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-SignedHeaders", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-Credential")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-Credential", valid_773743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773744: Call_GetDomainName_773733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_773744.validator(path, query, header, formData, body)
  let scheme = call_773744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773744.url(scheme.get, call_773744.host, call_773744.base,
                         call_773744.route, valid.getOrDefault("path"))
  result = hook(call_773744, url, valid)

proc call*(call_773745: Call_GetDomainName_773733; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_773746 = newJObject()
  add(path_773746, "domainName", newJString(domainName))
  result = call_773745.call(path_773746, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_773733(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_773734,
    base: "/", url: url_GetDomainName_773735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_773761 = ref object of OpenApiRestCall_772597
proc url_UpdateDomainName_773763(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_773762(path: JsonNode; query: JsonNode;
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
  var valid_773764 = path.getOrDefault("domainName")
  valid_773764 = validateParameter(valid_773764, JString, required = true,
                                 default = nil)
  if valid_773764 != nil:
    section.add "domainName", valid_773764
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
  var valid_773765 = header.getOrDefault("X-Amz-Date")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Date", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Security-Token")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Security-Token", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Content-Sha256", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Algorithm")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Algorithm", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-Signature")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Signature", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-SignedHeaders", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Credential")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Credential", valid_773771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773773: Call_UpdateDomainName_773761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_773773.validator(path, query, header, formData, body)
  let scheme = call_773773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773773.url(scheme.get, call_773773.host, call_773773.base,
                         call_773773.route, valid.getOrDefault("path"))
  result = hook(call_773773, url, valid)

proc call*(call_773774: Call_UpdateDomainName_773761; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_773775 = newJObject()
  var body_773776 = newJObject()
  add(path_773775, "domainName", newJString(domainName))
  if body != nil:
    body_773776 = body
  result = call_773774.call(path_773775, nil, nil, nil, body_773776)

var updateDomainName* = Call_UpdateDomainName_773761(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_773762,
    base: "/", url: url_UpdateDomainName_773763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_773747 = ref object of OpenApiRestCall_772597
proc url_DeleteDomainName_773749(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_773748(path: JsonNode; query: JsonNode;
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
  var valid_773750 = path.getOrDefault("domainName")
  valid_773750 = validateParameter(valid_773750, JString, required = true,
                                 default = nil)
  if valid_773750 != nil:
    section.add "domainName", valid_773750
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
  var valid_773751 = header.getOrDefault("X-Amz-Date")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Date", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Security-Token")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Security-Token", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Content-Sha256", valid_773753
  var valid_773754 = header.getOrDefault("X-Amz-Algorithm")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-Algorithm", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Signature")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Signature", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-SignedHeaders", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Credential")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Credential", valid_773757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773758: Call_DeleteDomainName_773747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_773758.validator(path, query, header, formData, body)
  let scheme = call_773758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773758.url(scheme.get, call_773758.host, call_773758.base,
                         call_773758.route, valid.getOrDefault("path"))
  result = hook(call_773758, url, valid)

proc call*(call_773759: Call_DeleteDomainName_773747; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_773760 = newJObject()
  add(path_773760, "domainName", newJString(domainName))
  result = call_773759.call(path_773760, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_773747(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_773748,
    base: "/", url: url_DeleteDomainName_773749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_773777 = ref object of OpenApiRestCall_772597
proc url_GetIntegration_773779(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_773778(path: JsonNode; query: JsonNode;
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
  var valid_773780 = path.getOrDefault("apiId")
  valid_773780 = validateParameter(valid_773780, JString, required = true,
                                 default = nil)
  if valid_773780 != nil:
    section.add "apiId", valid_773780
  var valid_773781 = path.getOrDefault("integrationId")
  valid_773781 = validateParameter(valid_773781, JString, required = true,
                                 default = nil)
  if valid_773781 != nil:
    section.add "integrationId", valid_773781
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
  var valid_773782 = header.getOrDefault("X-Amz-Date")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Date", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Security-Token")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Security-Token", valid_773783
  var valid_773784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Content-Sha256", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Algorithm")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Algorithm", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Signature")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Signature", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-SignedHeaders", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Credential")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Credential", valid_773788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773789: Call_GetIntegration_773777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_773789.validator(path, query, header, formData, body)
  let scheme = call_773789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773789.url(scheme.get, call_773789.host, call_773789.base,
                         call_773789.route, valid.getOrDefault("path"))
  result = hook(call_773789, url, valid)

proc call*(call_773790: Call_GetIntegration_773777; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_773791 = newJObject()
  add(path_773791, "apiId", newJString(apiId))
  add(path_773791, "integrationId", newJString(integrationId))
  result = call_773790.call(path_773791, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_773777(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_773778, base: "/", url: url_GetIntegration_773779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_773807 = ref object of OpenApiRestCall_772597
proc url_UpdateIntegration_773809(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_773808(path: JsonNode; query: JsonNode;
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
  var valid_773810 = path.getOrDefault("apiId")
  valid_773810 = validateParameter(valid_773810, JString, required = true,
                                 default = nil)
  if valid_773810 != nil:
    section.add "apiId", valid_773810
  var valid_773811 = path.getOrDefault("integrationId")
  valid_773811 = validateParameter(valid_773811, JString, required = true,
                                 default = nil)
  if valid_773811 != nil:
    section.add "integrationId", valid_773811
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
  var valid_773812 = header.getOrDefault("X-Amz-Date")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Date", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Security-Token")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Security-Token", valid_773813
  var valid_773814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-Content-Sha256", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Algorithm")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Algorithm", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-Signature")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-Signature", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-SignedHeaders", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Credential")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Credential", valid_773818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773820: Call_UpdateIntegration_773807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_773820.validator(path, query, header, formData, body)
  let scheme = call_773820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773820.url(scheme.get, call_773820.host, call_773820.base,
                         call_773820.route, valid.getOrDefault("path"))
  result = hook(call_773820, url, valid)

proc call*(call_773821: Call_UpdateIntegration_773807; apiId: string; body: JsonNode;
          integrationId: string): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_773822 = newJObject()
  var body_773823 = newJObject()
  add(path_773822, "apiId", newJString(apiId))
  if body != nil:
    body_773823 = body
  add(path_773822, "integrationId", newJString(integrationId))
  result = call_773821.call(path_773822, nil, nil, nil, body_773823)

var updateIntegration* = Call_UpdateIntegration_773807(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_773808, base: "/",
    url: url_UpdateIntegration_773809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_773792 = ref object of OpenApiRestCall_772597
proc url_DeleteIntegration_773794(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_773793(path: JsonNode; query: JsonNode;
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
  var valid_773795 = path.getOrDefault("apiId")
  valid_773795 = validateParameter(valid_773795, JString, required = true,
                                 default = nil)
  if valid_773795 != nil:
    section.add "apiId", valid_773795
  var valid_773796 = path.getOrDefault("integrationId")
  valid_773796 = validateParameter(valid_773796, JString, required = true,
                                 default = nil)
  if valid_773796 != nil:
    section.add "integrationId", valid_773796
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
  var valid_773797 = header.getOrDefault("X-Amz-Date")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Date", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Security-Token")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Security-Token", valid_773798
  var valid_773799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Content-Sha256", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Algorithm")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Algorithm", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Signature")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Signature", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-SignedHeaders", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-Credential")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Credential", valid_773803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773804: Call_DeleteIntegration_773792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_773804.validator(path, query, header, formData, body)
  let scheme = call_773804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773804.url(scheme.get, call_773804.host, call_773804.base,
                         call_773804.route, valid.getOrDefault("path"))
  result = hook(call_773804, url, valid)

proc call*(call_773805: Call_DeleteIntegration_773792; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_773806 = newJObject()
  add(path_773806, "apiId", newJString(apiId))
  add(path_773806, "integrationId", newJString(integrationId))
  result = call_773805.call(path_773806, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_773792(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_773793, base: "/",
    url: url_DeleteIntegration_773794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_773824 = ref object of OpenApiRestCall_772597
proc url_GetIntegrationResponse_773826(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_773825(path: JsonNode; query: JsonNode;
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
  var valid_773827 = path.getOrDefault("integrationResponseId")
  valid_773827 = validateParameter(valid_773827, JString, required = true,
                                 default = nil)
  if valid_773827 != nil:
    section.add "integrationResponseId", valid_773827
  var valid_773828 = path.getOrDefault("apiId")
  valid_773828 = validateParameter(valid_773828, JString, required = true,
                                 default = nil)
  if valid_773828 != nil:
    section.add "apiId", valid_773828
  var valid_773829 = path.getOrDefault("integrationId")
  valid_773829 = validateParameter(valid_773829, JString, required = true,
                                 default = nil)
  if valid_773829 != nil:
    section.add "integrationId", valid_773829
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
  var valid_773830 = header.getOrDefault("X-Amz-Date")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Date", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-Security-Token")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-Security-Token", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Content-Sha256", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-Algorithm")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-Algorithm", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-Signature")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Signature", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-SignedHeaders", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Credential")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Credential", valid_773836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773837: Call_GetIntegrationResponse_773824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_773837.validator(path, query, header, formData, body)
  let scheme = call_773837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773837.url(scheme.get, call_773837.host, call_773837.base,
                         call_773837.route, valid.getOrDefault("path"))
  result = hook(call_773837, url, valid)

proc call*(call_773838: Call_GetIntegrationResponse_773824;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_773839 = newJObject()
  add(path_773839, "integrationResponseId", newJString(integrationResponseId))
  add(path_773839, "apiId", newJString(apiId))
  add(path_773839, "integrationId", newJString(integrationId))
  result = call_773838.call(path_773839, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_773824(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_773825, base: "/",
    url: url_GetIntegrationResponse_773826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_773856 = ref object of OpenApiRestCall_772597
proc url_UpdateIntegrationResponse_773858(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_773857(path: JsonNode; query: JsonNode;
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
  var valid_773859 = path.getOrDefault("integrationResponseId")
  valid_773859 = validateParameter(valid_773859, JString, required = true,
                                 default = nil)
  if valid_773859 != nil:
    section.add "integrationResponseId", valid_773859
  var valid_773860 = path.getOrDefault("apiId")
  valid_773860 = validateParameter(valid_773860, JString, required = true,
                                 default = nil)
  if valid_773860 != nil:
    section.add "apiId", valid_773860
  var valid_773861 = path.getOrDefault("integrationId")
  valid_773861 = validateParameter(valid_773861, JString, required = true,
                                 default = nil)
  if valid_773861 != nil:
    section.add "integrationId", valid_773861
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
  var valid_773862 = header.getOrDefault("X-Amz-Date")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Date", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-Security-Token")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-Security-Token", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Content-Sha256", valid_773864
  var valid_773865 = header.getOrDefault("X-Amz-Algorithm")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-Algorithm", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-Signature")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Signature", valid_773866
  var valid_773867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-SignedHeaders", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-Credential")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-Credential", valid_773868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773870: Call_UpdateIntegrationResponse_773856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_773870.validator(path, query, header, formData, body)
  let scheme = call_773870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773870.url(scheme.get, call_773870.host, call_773870.base,
                         call_773870.route, valid.getOrDefault("path"))
  result = hook(call_773870, url, valid)

proc call*(call_773871: Call_UpdateIntegrationResponse_773856;
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
  var path_773872 = newJObject()
  var body_773873 = newJObject()
  add(path_773872, "integrationResponseId", newJString(integrationResponseId))
  add(path_773872, "apiId", newJString(apiId))
  if body != nil:
    body_773873 = body
  add(path_773872, "integrationId", newJString(integrationId))
  result = call_773871.call(path_773872, nil, nil, nil, body_773873)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_773856(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_773857, base: "/",
    url: url_UpdateIntegrationResponse_773858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_773840 = ref object of OpenApiRestCall_772597
proc url_DeleteIntegrationResponse_773842(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_773841(path: JsonNode; query: JsonNode;
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
  var valid_773843 = path.getOrDefault("integrationResponseId")
  valid_773843 = validateParameter(valid_773843, JString, required = true,
                                 default = nil)
  if valid_773843 != nil:
    section.add "integrationResponseId", valid_773843
  var valid_773844 = path.getOrDefault("apiId")
  valid_773844 = validateParameter(valid_773844, JString, required = true,
                                 default = nil)
  if valid_773844 != nil:
    section.add "apiId", valid_773844
  var valid_773845 = path.getOrDefault("integrationId")
  valid_773845 = validateParameter(valid_773845, JString, required = true,
                                 default = nil)
  if valid_773845 != nil:
    section.add "integrationId", valid_773845
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
  var valid_773846 = header.getOrDefault("X-Amz-Date")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "X-Amz-Date", valid_773846
  var valid_773847 = header.getOrDefault("X-Amz-Security-Token")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Security-Token", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-Content-Sha256", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Algorithm")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Algorithm", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-Signature")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Signature", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-SignedHeaders", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-Credential")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Credential", valid_773852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773853: Call_DeleteIntegrationResponse_773840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_773853.validator(path, query, header, formData, body)
  let scheme = call_773853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773853.url(scheme.get, call_773853.host, call_773853.base,
                         call_773853.route, valid.getOrDefault("path"))
  result = hook(call_773853, url, valid)

proc call*(call_773854: Call_DeleteIntegrationResponse_773840;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_773855 = newJObject()
  add(path_773855, "integrationResponseId", newJString(integrationResponseId))
  add(path_773855, "apiId", newJString(apiId))
  add(path_773855, "integrationId", newJString(integrationId))
  result = call_773854.call(path_773855, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_773840(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_773841, base: "/",
    url: url_DeleteIntegrationResponse_773842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_773874 = ref object of OpenApiRestCall_772597
proc url_GetModel_773876(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_773875(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773877 = path.getOrDefault("apiId")
  valid_773877 = validateParameter(valid_773877, JString, required = true,
                                 default = nil)
  if valid_773877 != nil:
    section.add "apiId", valid_773877
  var valid_773878 = path.getOrDefault("modelId")
  valid_773878 = validateParameter(valid_773878, JString, required = true,
                                 default = nil)
  if valid_773878 != nil:
    section.add "modelId", valid_773878
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
  var valid_773879 = header.getOrDefault("X-Amz-Date")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Date", valid_773879
  var valid_773880 = header.getOrDefault("X-Amz-Security-Token")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Security-Token", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Content-Sha256", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Algorithm")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Algorithm", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Signature")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Signature", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-SignedHeaders", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Credential")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Credential", valid_773885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773886: Call_GetModel_773874; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_773886.validator(path, query, header, formData, body)
  let scheme = call_773886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773886.url(scheme.get, call_773886.host, call_773886.base,
                         call_773886.route, valid.getOrDefault("path"))
  result = hook(call_773886, url, valid)

proc call*(call_773887: Call_GetModel_773874; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_773888 = newJObject()
  add(path_773888, "apiId", newJString(apiId))
  add(path_773888, "modelId", newJString(modelId))
  result = call_773887.call(path_773888, nil, nil, nil, nil)

var getModel* = Call_GetModel_773874(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_773875, base: "/",
                                  url: url_GetModel_773876,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_773904 = ref object of OpenApiRestCall_772597
proc url_UpdateModel_773906(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_773905(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773907 = path.getOrDefault("apiId")
  valid_773907 = validateParameter(valid_773907, JString, required = true,
                                 default = nil)
  if valid_773907 != nil:
    section.add "apiId", valid_773907
  var valid_773908 = path.getOrDefault("modelId")
  valid_773908 = validateParameter(valid_773908, JString, required = true,
                                 default = nil)
  if valid_773908 != nil:
    section.add "modelId", valid_773908
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
  var valid_773909 = header.getOrDefault("X-Amz-Date")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-Date", valid_773909
  var valid_773910 = header.getOrDefault("X-Amz-Security-Token")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Security-Token", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Content-Sha256", valid_773911
  var valid_773912 = header.getOrDefault("X-Amz-Algorithm")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-Algorithm", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Signature")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Signature", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-SignedHeaders", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-Credential")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Credential", valid_773915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773917: Call_UpdateModel_773904; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_773917.validator(path, query, header, formData, body)
  let scheme = call_773917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773917.url(scheme.get, call_773917.host, call_773917.base,
                         call_773917.route, valid.getOrDefault("path"))
  result = hook(call_773917, url, valid)

proc call*(call_773918: Call_UpdateModel_773904; apiId: string; modelId: string;
          body: JsonNode): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  ##   body: JObject (required)
  var path_773919 = newJObject()
  var body_773920 = newJObject()
  add(path_773919, "apiId", newJString(apiId))
  add(path_773919, "modelId", newJString(modelId))
  if body != nil:
    body_773920 = body
  result = call_773918.call(path_773919, nil, nil, nil, body_773920)

var updateModel* = Call_UpdateModel_773904(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_773905,
                                        base: "/", url: url_UpdateModel_773906,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_773889 = ref object of OpenApiRestCall_772597
proc url_DeleteModel_773891(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_773890(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773892 = path.getOrDefault("apiId")
  valid_773892 = validateParameter(valid_773892, JString, required = true,
                                 default = nil)
  if valid_773892 != nil:
    section.add "apiId", valid_773892
  var valid_773893 = path.getOrDefault("modelId")
  valid_773893 = validateParameter(valid_773893, JString, required = true,
                                 default = nil)
  if valid_773893 != nil:
    section.add "modelId", valid_773893
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
  var valid_773894 = header.getOrDefault("X-Amz-Date")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-Date", valid_773894
  var valid_773895 = header.getOrDefault("X-Amz-Security-Token")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Security-Token", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Content-Sha256", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Algorithm")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Algorithm", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-Signature")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-Signature", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-SignedHeaders", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-Credential")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-Credential", valid_773900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773901: Call_DeleteModel_773889; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_773901.validator(path, query, header, formData, body)
  let scheme = call_773901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773901.url(scheme.get, call_773901.host, call_773901.base,
                         call_773901.route, valid.getOrDefault("path"))
  result = hook(call_773901, url, valid)

proc call*(call_773902: Call_DeleteModel_773889; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_773903 = newJObject()
  add(path_773903, "apiId", newJString(apiId))
  add(path_773903, "modelId", newJString(modelId))
  result = call_773902.call(path_773903, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_773889(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_773890,
                                        base: "/", url: url_DeleteModel_773891,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_773921 = ref object of OpenApiRestCall_772597
proc url_GetRoute_773923(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoute_773922(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773924 = path.getOrDefault("apiId")
  valid_773924 = validateParameter(valid_773924, JString, required = true,
                                 default = nil)
  if valid_773924 != nil:
    section.add "apiId", valid_773924
  var valid_773925 = path.getOrDefault("routeId")
  valid_773925 = validateParameter(valid_773925, JString, required = true,
                                 default = nil)
  if valid_773925 != nil:
    section.add "routeId", valid_773925
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
  var valid_773926 = header.getOrDefault("X-Amz-Date")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Date", valid_773926
  var valid_773927 = header.getOrDefault("X-Amz-Security-Token")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-Security-Token", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Content-Sha256", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Algorithm")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Algorithm", valid_773929
  var valid_773930 = header.getOrDefault("X-Amz-Signature")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-Signature", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-SignedHeaders", valid_773931
  var valid_773932 = header.getOrDefault("X-Amz-Credential")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-Credential", valid_773932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773933: Call_GetRoute_773921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_773933.validator(path, query, header, formData, body)
  let scheme = call_773933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773933.url(scheme.get, call_773933.host, call_773933.base,
                         call_773933.route, valid.getOrDefault("path"))
  result = hook(call_773933, url, valid)

proc call*(call_773934: Call_GetRoute_773921; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_773935 = newJObject()
  add(path_773935, "apiId", newJString(apiId))
  add(path_773935, "routeId", newJString(routeId))
  result = call_773934.call(path_773935, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_773921(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_773922, base: "/",
                                  url: url_GetRoute_773923,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_773951 = ref object of OpenApiRestCall_772597
proc url_UpdateRoute_773953(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_773952(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773954 = path.getOrDefault("apiId")
  valid_773954 = validateParameter(valid_773954, JString, required = true,
                                 default = nil)
  if valid_773954 != nil:
    section.add "apiId", valid_773954
  var valid_773955 = path.getOrDefault("routeId")
  valid_773955 = validateParameter(valid_773955, JString, required = true,
                                 default = nil)
  if valid_773955 != nil:
    section.add "routeId", valid_773955
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
  var valid_773956 = header.getOrDefault("X-Amz-Date")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Date", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Security-Token")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Security-Token", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-Content-Sha256", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-Algorithm")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-Algorithm", valid_773959
  var valid_773960 = header.getOrDefault("X-Amz-Signature")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-Signature", valid_773960
  var valid_773961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-SignedHeaders", valid_773961
  var valid_773962 = header.getOrDefault("X-Amz-Credential")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "X-Amz-Credential", valid_773962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773964: Call_UpdateRoute_773951; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_773964.validator(path, query, header, formData, body)
  let scheme = call_773964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773964.url(scheme.get, call_773964.host, call_773964.base,
                         call_773964.route, valid.getOrDefault("path"))
  result = hook(call_773964, url, valid)

proc call*(call_773965: Call_UpdateRoute_773951; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_773966 = newJObject()
  var body_773967 = newJObject()
  add(path_773966, "apiId", newJString(apiId))
  if body != nil:
    body_773967 = body
  add(path_773966, "routeId", newJString(routeId))
  result = call_773965.call(path_773966, nil, nil, nil, body_773967)

var updateRoute* = Call_UpdateRoute_773951(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_773952,
                                        base: "/", url: url_UpdateRoute_773953,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_773936 = ref object of OpenApiRestCall_772597
proc url_DeleteRoute_773938(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_773937(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773939 = path.getOrDefault("apiId")
  valid_773939 = validateParameter(valid_773939, JString, required = true,
                                 default = nil)
  if valid_773939 != nil:
    section.add "apiId", valid_773939
  var valid_773940 = path.getOrDefault("routeId")
  valid_773940 = validateParameter(valid_773940, JString, required = true,
                                 default = nil)
  if valid_773940 != nil:
    section.add "routeId", valid_773940
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
  var valid_773941 = header.getOrDefault("X-Amz-Date")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Date", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-Security-Token")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Security-Token", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Content-Sha256", valid_773943
  var valid_773944 = header.getOrDefault("X-Amz-Algorithm")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "X-Amz-Algorithm", valid_773944
  var valid_773945 = header.getOrDefault("X-Amz-Signature")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-Signature", valid_773945
  var valid_773946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "X-Amz-SignedHeaders", valid_773946
  var valid_773947 = header.getOrDefault("X-Amz-Credential")
  valid_773947 = validateParameter(valid_773947, JString, required = false,
                                 default = nil)
  if valid_773947 != nil:
    section.add "X-Amz-Credential", valid_773947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773948: Call_DeleteRoute_773936; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_773948.validator(path, query, header, formData, body)
  let scheme = call_773948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773948.url(scheme.get, call_773948.host, call_773948.base,
                         call_773948.route, valid.getOrDefault("path"))
  result = hook(call_773948, url, valid)

proc call*(call_773949: Call_DeleteRoute_773936; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_773950 = newJObject()
  add(path_773950, "apiId", newJString(apiId))
  add(path_773950, "routeId", newJString(routeId))
  result = call_773949.call(path_773950, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_773936(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_773937,
                                        base: "/", url: url_DeleteRoute_773938,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_773968 = ref object of OpenApiRestCall_772597
proc url_GetRouteResponse_773970(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponse_773969(path: JsonNode; query: JsonNode;
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
  var valid_773971 = path.getOrDefault("apiId")
  valid_773971 = validateParameter(valid_773971, JString, required = true,
                                 default = nil)
  if valid_773971 != nil:
    section.add "apiId", valid_773971
  var valid_773972 = path.getOrDefault("routeResponseId")
  valid_773972 = validateParameter(valid_773972, JString, required = true,
                                 default = nil)
  if valid_773972 != nil:
    section.add "routeResponseId", valid_773972
  var valid_773973 = path.getOrDefault("routeId")
  valid_773973 = validateParameter(valid_773973, JString, required = true,
                                 default = nil)
  if valid_773973 != nil:
    section.add "routeId", valid_773973
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
  var valid_773974 = header.getOrDefault("X-Amz-Date")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "X-Amz-Date", valid_773974
  var valid_773975 = header.getOrDefault("X-Amz-Security-Token")
  valid_773975 = validateParameter(valid_773975, JString, required = false,
                                 default = nil)
  if valid_773975 != nil:
    section.add "X-Amz-Security-Token", valid_773975
  var valid_773976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773976 = validateParameter(valid_773976, JString, required = false,
                                 default = nil)
  if valid_773976 != nil:
    section.add "X-Amz-Content-Sha256", valid_773976
  var valid_773977 = header.getOrDefault("X-Amz-Algorithm")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "X-Amz-Algorithm", valid_773977
  var valid_773978 = header.getOrDefault("X-Amz-Signature")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "X-Amz-Signature", valid_773978
  var valid_773979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "X-Amz-SignedHeaders", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-Credential")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-Credential", valid_773980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773981: Call_GetRouteResponse_773968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_773981.validator(path, query, header, formData, body)
  let scheme = call_773981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773981.url(scheme.get, call_773981.host, call_773981.base,
                         call_773981.route, valid.getOrDefault("path"))
  result = hook(call_773981, url, valid)

proc call*(call_773982: Call_GetRouteResponse_773968; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_773983 = newJObject()
  add(path_773983, "apiId", newJString(apiId))
  add(path_773983, "routeResponseId", newJString(routeResponseId))
  add(path_773983, "routeId", newJString(routeId))
  result = call_773982.call(path_773983, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_773968(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_773969, base: "/",
    url: url_GetRouteResponse_773970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_774000 = ref object of OpenApiRestCall_772597
proc url_UpdateRouteResponse_774002(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRouteResponse_774001(path: JsonNode; query: JsonNode;
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
  var valid_774003 = path.getOrDefault("apiId")
  valid_774003 = validateParameter(valid_774003, JString, required = true,
                                 default = nil)
  if valid_774003 != nil:
    section.add "apiId", valid_774003
  var valid_774004 = path.getOrDefault("routeResponseId")
  valid_774004 = validateParameter(valid_774004, JString, required = true,
                                 default = nil)
  if valid_774004 != nil:
    section.add "routeResponseId", valid_774004
  var valid_774005 = path.getOrDefault("routeId")
  valid_774005 = validateParameter(valid_774005, JString, required = true,
                                 default = nil)
  if valid_774005 != nil:
    section.add "routeId", valid_774005
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
  var valid_774006 = header.getOrDefault("X-Amz-Date")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Date", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-Security-Token")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Security-Token", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Content-Sha256", valid_774008
  var valid_774009 = header.getOrDefault("X-Amz-Algorithm")
  valid_774009 = validateParameter(valid_774009, JString, required = false,
                                 default = nil)
  if valid_774009 != nil:
    section.add "X-Amz-Algorithm", valid_774009
  var valid_774010 = header.getOrDefault("X-Amz-Signature")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-Signature", valid_774010
  var valid_774011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "X-Amz-SignedHeaders", valid_774011
  var valid_774012 = header.getOrDefault("X-Amz-Credential")
  valid_774012 = validateParameter(valid_774012, JString, required = false,
                                 default = nil)
  if valid_774012 != nil:
    section.add "X-Amz-Credential", valid_774012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774014: Call_UpdateRouteResponse_774000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_774014.validator(path, query, header, formData, body)
  let scheme = call_774014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774014.url(scheme.get, call_774014.host, call_774014.base,
                         call_774014.route, valid.getOrDefault("path"))
  result = hook(call_774014, url, valid)

proc call*(call_774015: Call_UpdateRouteResponse_774000; apiId: string;
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
  var path_774016 = newJObject()
  var body_774017 = newJObject()
  add(path_774016, "apiId", newJString(apiId))
  add(path_774016, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_774017 = body
  add(path_774016, "routeId", newJString(routeId))
  result = call_774015.call(path_774016, nil, nil, nil, body_774017)

var updateRouteResponse* = Call_UpdateRouteResponse_774000(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_774001, base: "/",
    url: url_UpdateRouteResponse_774002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_773984 = ref object of OpenApiRestCall_772597
proc url_DeleteRouteResponse_773986(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRouteResponse_773985(path: JsonNode; query: JsonNode;
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
  var valid_773987 = path.getOrDefault("apiId")
  valid_773987 = validateParameter(valid_773987, JString, required = true,
                                 default = nil)
  if valid_773987 != nil:
    section.add "apiId", valid_773987
  var valid_773988 = path.getOrDefault("routeResponseId")
  valid_773988 = validateParameter(valid_773988, JString, required = true,
                                 default = nil)
  if valid_773988 != nil:
    section.add "routeResponseId", valid_773988
  var valid_773989 = path.getOrDefault("routeId")
  valid_773989 = validateParameter(valid_773989, JString, required = true,
                                 default = nil)
  if valid_773989 != nil:
    section.add "routeId", valid_773989
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
  var valid_773990 = header.getOrDefault("X-Amz-Date")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Date", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-Security-Token")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-Security-Token", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Content-Sha256", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Algorithm")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Algorithm", valid_773993
  var valid_773994 = header.getOrDefault("X-Amz-Signature")
  valid_773994 = validateParameter(valid_773994, JString, required = false,
                                 default = nil)
  if valid_773994 != nil:
    section.add "X-Amz-Signature", valid_773994
  var valid_773995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-SignedHeaders", valid_773995
  var valid_773996 = header.getOrDefault("X-Amz-Credential")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "X-Amz-Credential", valid_773996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773997: Call_DeleteRouteResponse_773984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_773997.validator(path, query, header, formData, body)
  let scheme = call_773997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773997.url(scheme.get, call_773997.host, call_773997.base,
                         call_773997.route, valid.getOrDefault("path"))
  result = hook(call_773997, url, valid)

proc call*(call_773998: Call_DeleteRouteResponse_773984; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_773999 = newJObject()
  add(path_773999, "apiId", newJString(apiId))
  add(path_773999, "routeResponseId", newJString(routeResponseId))
  add(path_773999, "routeId", newJString(routeId))
  result = call_773998.call(path_773999, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_773984(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_773985, base: "/",
    url: url_DeleteRouteResponse_773986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_774018 = ref object of OpenApiRestCall_772597
proc url_GetStage_774020(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_774019(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774021 = path.getOrDefault("stageName")
  valid_774021 = validateParameter(valid_774021, JString, required = true,
                                 default = nil)
  if valid_774021 != nil:
    section.add "stageName", valid_774021
  var valid_774022 = path.getOrDefault("apiId")
  valid_774022 = validateParameter(valid_774022, JString, required = true,
                                 default = nil)
  if valid_774022 != nil:
    section.add "apiId", valid_774022
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
  var valid_774023 = header.getOrDefault("X-Amz-Date")
  valid_774023 = validateParameter(valid_774023, JString, required = false,
                                 default = nil)
  if valid_774023 != nil:
    section.add "X-Amz-Date", valid_774023
  var valid_774024 = header.getOrDefault("X-Amz-Security-Token")
  valid_774024 = validateParameter(valid_774024, JString, required = false,
                                 default = nil)
  if valid_774024 != nil:
    section.add "X-Amz-Security-Token", valid_774024
  var valid_774025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Content-Sha256", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Algorithm")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Algorithm", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Signature")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Signature", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-SignedHeaders", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Credential")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Credential", valid_774029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774030: Call_GetStage_774018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_774030.validator(path, query, header, formData, body)
  let scheme = call_774030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774030.url(scheme.get, call_774030.host, call_774030.base,
                         call_774030.route, valid.getOrDefault("path"))
  result = hook(call_774030, url, valid)

proc call*(call_774031: Call_GetStage_774018; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_774032 = newJObject()
  add(path_774032, "stageName", newJString(stageName))
  add(path_774032, "apiId", newJString(apiId))
  result = call_774031.call(path_774032, nil, nil, nil, nil)

var getStage* = Call_GetStage_774018(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_774019, base: "/",
                                  url: url_GetStage_774020,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_774048 = ref object of OpenApiRestCall_772597
proc url_UpdateStage_774050(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_774049(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774051 = path.getOrDefault("stageName")
  valid_774051 = validateParameter(valid_774051, JString, required = true,
                                 default = nil)
  if valid_774051 != nil:
    section.add "stageName", valid_774051
  var valid_774052 = path.getOrDefault("apiId")
  valid_774052 = validateParameter(valid_774052, JString, required = true,
                                 default = nil)
  if valid_774052 != nil:
    section.add "apiId", valid_774052
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
  var valid_774053 = header.getOrDefault("X-Amz-Date")
  valid_774053 = validateParameter(valid_774053, JString, required = false,
                                 default = nil)
  if valid_774053 != nil:
    section.add "X-Amz-Date", valid_774053
  var valid_774054 = header.getOrDefault("X-Amz-Security-Token")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "X-Amz-Security-Token", valid_774054
  var valid_774055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Content-Sha256", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Algorithm")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Algorithm", valid_774056
  var valid_774057 = header.getOrDefault("X-Amz-Signature")
  valid_774057 = validateParameter(valid_774057, JString, required = false,
                                 default = nil)
  if valid_774057 != nil:
    section.add "X-Amz-Signature", valid_774057
  var valid_774058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "X-Amz-SignedHeaders", valid_774058
  var valid_774059 = header.getOrDefault("X-Amz-Credential")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "X-Amz-Credential", valid_774059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774061: Call_UpdateStage_774048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_774061.validator(path, query, header, formData, body)
  let scheme = call_774061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774061.url(scheme.get, call_774061.host, call_774061.base,
                         call_774061.route, valid.getOrDefault("path"))
  result = hook(call_774061, url, valid)

proc call*(call_774062: Call_UpdateStage_774048; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_774063 = newJObject()
  var body_774064 = newJObject()
  add(path_774063, "stageName", newJString(stageName))
  add(path_774063, "apiId", newJString(apiId))
  if body != nil:
    body_774064 = body
  result = call_774062.call(path_774063, nil, nil, nil, body_774064)

var updateStage* = Call_UpdateStage_774048(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_774049,
                                        base: "/", url: url_UpdateStage_774050,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_774033 = ref object of OpenApiRestCall_772597
proc url_DeleteStage_774035(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_774034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774036 = path.getOrDefault("stageName")
  valid_774036 = validateParameter(valid_774036, JString, required = true,
                                 default = nil)
  if valid_774036 != nil:
    section.add "stageName", valid_774036
  var valid_774037 = path.getOrDefault("apiId")
  valid_774037 = validateParameter(valid_774037, JString, required = true,
                                 default = nil)
  if valid_774037 != nil:
    section.add "apiId", valid_774037
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
  var valid_774038 = header.getOrDefault("X-Amz-Date")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Date", valid_774038
  var valid_774039 = header.getOrDefault("X-Amz-Security-Token")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-Security-Token", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Content-Sha256", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Algorithm")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Algorithm", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Signature")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Signature", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-SignedHeaders", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Credential")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Credential", valid_774044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774045: Call_DeleteStage_774033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_774045.validator(path, query, header, formData, body)
  let scheme = call_774045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774045.url(scheme.get, call_774045.host, call_774045.base,
                         call_774045.route, valid.getOrDefault("path"))
  result = hook(call_774045, url, valid)

proc call*(call_774046: Call_DeleteStage_774033; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_774047 = newJObject()
  add(path_774047, "stageName", newJString(stageName))
  add(path_774047, "apiId", newJString(apiId))
  result = call_774046.call(path_774047, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_774033(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_774034,
                                        base: "/", url: url_DeleteStage_774035,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_774065 = ref object of OpenApiRestCall_772597
proc url_GetModelTemplate_774067(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_774066(path: JsonNode; query: JsonNode;
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
  var valid_774068 = path.getOrDefault("apiId")
  valid_774068 = validateParameter(valid_774068, JString, required = true,
                                 default = nil)
  if valid_774068 != nil:
    section.add "apiId", valid_774068
  var valid_774069 = path.getOrDefault("modelId")
  valid_774069 = validateParameter(valid_774069, JString, required = true,
                                 default = nil)
  if valid_774069 != nil:
    section.add "modelId", valid_774069
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
  var valid_774070 = header.getOrDefault("X-Amz-Date")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Date", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Security-Token")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Security-Token", valid_774071
  var valid_774072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "X-Amz-Content-Sha256", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-Algorithm")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Algorithm", valid_774073
  var valid_774074 = header.getOrDefault("X-Amz-Signature")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-Signature", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-SignedHeaders", valid_774075
  var valid_774076 = header.getOrDefault("X-Amz-Credential")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Credential", valid_774076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774077: Call_GetModelTemplate_774065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_774077.validator(path, query, header, formData, body)
  let scheme = call_774077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774077.url(scheme.get, call_774077.host, call_774077.base,
                         call_774077.route, valid.getOrDefault("path"))
  result = hook(call_774077, url, valid)

proc call*(call_774078: Call_GetModelTemplate_774065; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_774079 = newJObject()
  add(path_774079, "apiId", newJString(apiId))
  add(path_774079, "modelId", newJString(modelId))
  result = call_774078.call(path_774079, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_774065(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_774066, base: "/",
    url: url_GetModelTemplate_774067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774094 = ref object of OpenApiRestCall_772597
proc url_TagResource_774096(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_774095(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774097 = path.getOrDefault("resource-arn")
  valid_774097 = validateParameter(valid_774097, JString, required = true,
                                 default = nil)
  if valid_774097 != nil:
    section.add "resource-arn", valid_774097
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
  var valid_774098 = header.getOrDefault("X-Amz-Date")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "X-Amz-Date", valid_774098
  var valid_774099 = header.getOrDefault("X-Amz-Security-Token")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Security-Token", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Content-Sha256", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Algorithm")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Algorithm", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-Signature")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-Signature", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-SignedHeaders", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-Credential")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-Credential", valid_774104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774106: Call_TagResource_774094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tag an APIGW resource
  ## 
  let valid = call_774106.validator(path, query, header, formData, body)
  let scheme = call_774106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774106.url(scheme.get, call_774106.host, call_774106.base,
                         call_774106.route, valid.getOrDefault("path"))
  result = hook(call_774106, url, valid)

proc call*(call_774107: Call_TagResource_774094; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tag an APIGW resource
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  ##   body: JObject (required)
  var path_774108 = newJObject()
  var body_774109 = newJObject()
  add(path_774108, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_774109 = body
  result = call_774107.call(path_774108, nil, nil, nil, body_774109)

var tagResource* = Call_TagResource_774094(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_774095,
                                        base: "/", url: url_TagResource_774096,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_774080 = ref object of OpenApiRestCall_772597
proc url_GetTags_774082(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_774081(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774083 = path.getOrDefault("resource-arn")
  valid_774083 = validateParameter(valid_774083, JString, required = true,
                                 default = nil)
  if valid_774083 != nil:
    section.add "resource-arn", valid_774083
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
  var valid_774084 = header.getOrDefault("X-Amz-Date")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Date", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-Security-Token")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Security-Token", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Content-Sha256", valid_774086
  var valid_774087 = header.getOrDefault("X-Amz-Algorithm")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "X-Amz-Algorithm", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-Signature")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-Signature", valid_774088
  var valid_774089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-SignedHeaders", valid_774089
  var valid_774090 = header.getOrDefault("X-Amz-Credential")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-Credential", valid_774090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774091: Call_GetTags_774080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Tags for an API.
  ## 
  let valid = call_774091.validator(path, query, header, formData, body)
  let scheme = call_774091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774091.url(scheme.get, call_774091.host, call_774091.base,
                         call_774091.route, valid.getOrDefault("path"))
  result = hook(call_774091, url, valid)

proc call*(call_774092: Call_GetTags_774080; resourceArn: string): Recallable =
  ## getTags
  ## Gets the Tags for an API.
  ##   resourceArn: string (required)
  var path_774093 = newJObject()
  add(path_774093, "resource-arn", newJString(resourceArn))
  result = call_774092.call(path_774093, nil, nil, nil, nil)

var getTags* = Call_GetTags_774080(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_774081, base: "/",
                                url: url_GetTags_774082,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774110 = ref object of OpenApiRestCall_772597
proc url_UntagResource_774112(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_774111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774113 = path.getOrDefault("resource-arn")
  valid_774113 = validateParameter(valid_774113, JString, required = true,
                                 default = nil)
  if valid_774113 != nil:
    section.add "resource-arn", valid_774113
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_774114 = query.getOrDefault("tagKeys")
  valid_774114 = validateParameter(valid_774114, JArray, required = true, default = nil)
  if valid_774114 != nil:
    section.add "tagKeys", valid_774114
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
  var valid_774115 = header.getOrDefault("X-Amz-Date")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Date", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Security-Token")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Security-Token", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Content-Sha256", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Algorithm")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Algorithm", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Signature")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Signature", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-SignedHeaders", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-Credential")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-Credential", valid_774121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774122: Call_UntagResource_774110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untag an APIGW resource
  ## 
  let valid = call_774122.validator(path, query, header, formData, body)
  let scheme = call_774122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774122.url(scheme.get, call_774122.host, call_774122.base,
                         call_774122.route, valid.getOrDefault("path"))
  result = hook(call_774122, url, valid)

proc call*(call_774123: Call_UntagResource_774110; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Untag an APIGW resource
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  var path_774124 = newJObject()
  var query_774125 = newJObject()
  if tagKeys != nil:
    query_774125.add "tagKeys", tagKeys
  add(path_774124, "resource-arn", newJString(resourceArn))
  result = call_774123.call(path_774124, query_774125, nil, nil, nil)

var untagResource* = Call_UntagResource_774110(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_774111,
    base: "/", url: url_UntagResource_774112, schemes: {Scheme.Https, Scheme.Http})
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
