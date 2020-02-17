
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ImportApi_611253 = ref object of OpenApiRestCall_610658
proc url_ImportApi_611255(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApi_611254(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Imports an API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  section = newJObject()
  var valid_611256 = query.getOrDefault("failOnWarnings")
  valid_611256 = validateParameter(valid_611256, JBool, required = false, default = nil)
  if valid_611256 != nil:
    section.add "failOnWarnings", valid_611256
  var valid_611257 = query.getOrDefault("basepath")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "basepath", valid_611257
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
  var valid_611258 = header.getOrDefault("X-Amz-Signature")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Signature", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Content-Sha256", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Date")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Date", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Credential")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Credential", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Security-Token")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Security-Token", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-Algorithm")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Algorithm", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-SignedHeaders", valid_611264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611266: Call_ImportApi_611253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an API.
  ## 
  let valid = call_611266.validator(path, query, header, formData, body)
  let scheme = call_611266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611266.url(scheme.get, call_611266.host, call_611266.base,
                         call_611266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611266, url, valid)

proc call*(call_611267: Call_ImportApi_611253; body: JsonNode;
          failOnWarnings: bool = false; basepath: string = ""): Recallable =
  ## importApi
  ## Imports an API.
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   body: JObject (required)
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  var query_611268 = newJObject()
  var body_611269 = newJObject()
  add(query_611268, "failOnWarnings", newJBool(failOnWarnings))
  if body != nil:
    body_611269 = body
  add(query_611268, "basepath", newJString(basepath))
  result = call_611267.call(nil, query_611268, nil, nil, body_611269)

var importApi* = Call_ImportApi_611253(name: "importApi", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_ImportApi_611254,
                                    base: "/", url: url_ImportApi_611255,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApi_611270 = ref object of OpenApiRestCall_610658
proc url_CreateApi_611272(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApi_611271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611273 = header.getOrDefault("X-Amz-Signature")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Signature", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Content-Sha256", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Date")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Date", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Credential")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Credential", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Security-Token")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Security-Token", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Algorithm")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Algorithm", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-SignedHeaders", valid_611279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611281: Call_CreateApi_611270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_611281.validator(path, query, header, formData, body)
  let scheme = call_611281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611281.url(scheme.get, call_611281.host, call_611281.base,
                         call_611281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611281, url, valid)

proc call*(call_611282: Call_CreateApi_611270; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_611283 = newJObject()
  if body != nil:
    body_611283 = body
  result = call_611282.call(nil, nil, nil, nil, body_611283)

var createApi* = Call_CreateApi_611270(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_611271,
                                    base: "/", url: url_CreateApi_611272,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_610996 = ref object of OpenApiRestCall_610658
proc url_GetApis_610998(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApis_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of Api resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611110 = query.getOrDefault("nextToken")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "nextToken", valid_611110
  var valid_611111 = query.getOrDefault("maxResults")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "maxResults", valid_611111
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
  var valid_611112 = header.getOrDefault("X-Amz-Signature")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Signature", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Content-Sha256", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Date")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Date", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Credential")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Credential", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Security-Token")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Security-Token", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Algorithm")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Algorithm", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-SignedHeaders", valid_611118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611141: Call_GetApis_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_611141.validator(path, query, header, formData, body)
  let scheme = call_611141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611141.url(scheme.get, call_611141.host, call_611141.base,
                         call_611141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611141, url, valid)

proc call*(call_611212: Call_GetApis_610996; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_611213 = newJObject()
  add(query_611213, "nextToken", newJString(nextToken))
  add(query_611213, "maxResults", newJString(maxResults))
  result = call_611212.call(nil, query_611213, nil, nil, nil)

var getApis* = Call_GetApis_610996(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_610997,
                                base: "/", url: url_GetApis_610998,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_611315 = ref object of OpenApiRestCall_610658
proc url_CreateApiMapping_611317(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiMapping_611316(path: JsonNode; query: JsonNode;
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
  var valid_611318 = path.getOrDefault("domainName")
  valid_611318 = validateParameter(valid_611318, JString, required = true,
                                 default = nil)
  if valid_611318 != nil:
    section.add "domainName", valid_611318
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

proc call*(call_611327: Call_CreateApiMapping_611315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_611327.validator(path, query, header, formData, body)
  let scheme = call_611327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611327.url(scheme.get, call_611327.host, call_611327.base,
                         call_611327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611327, url, valid)

proc call*(call_611328: Call_CreateApiMapping_611315; body: JsonNode;
          domainName: string): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_611329 = newJObject()
  var body_611330 = newJObject()
  if body != nil:
    body_611330 = body
  add(path_611329, "domainName", newJString(domainName))
  result = call_611328.call(path_611329, nil, nil, nil, body_611330)

var createApiMapping* = Call_CreateApiMapping_611315(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_611316, base: "/",
    url: url_CreateApiMapping_611317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_611284 = ref object of OpenApiRestCall_610658
proc url_GetApiMappings_611286(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMappings_611285(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets API mappings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_611301 = path.getOrDefault("domainName")
  valid_611301 = validateParameter(valid_611301, JString, required = true,
                                 default = nil)
  if valid_611301 != nil:
    section.add "domainName", valid_611301
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611302 = query.getOrDefault("nextToken")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "nextToken", valid_611302
  var valid_611303 = query.getOrDefault("maxResults")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "maxResults", valid_611303
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
  var valid_611304 = header.getOrDefault("X-Amz-Signature")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Signature", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Content-Sha256", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Date")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Date", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Credential")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Credential", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Security-Token")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Security-Token", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Algorithm")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Algorithm", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-SignedHeaders", valid_611310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611311: Call_GetApiMappings_611284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets API mappings.
  ## 
  let valid = call_611311.validator(path, query, header, formData, body)
  let scheme = call_611311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611311.url(scheme.get, call_611311.host, call_611311.base,
                         call_611311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611311, url, valid)

proc call*(call_611312: Call_GetApiMappings_611284; domainName: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getApiMappings
  ## Gets API mappings.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611313 = newJObject()
  var query_611314 = newJObject()
  add(query_611314, "nextToken", newJString(nextToken))
  add(path_611313, "domainName", newJString(domainName))
  add(query_611314, "maxResults", newJString(maxResults))
  result = call_611312.call(path_611313, query_611314, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_611284(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_611285, base: "/", url: url_GetApiMappings_611286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_611348 = ref object of OpenApiRestCall_610658
proc url_CreateAuthorizer_611350(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAuthorizer_611349(path: JsonNode; query: JsonNode;
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
  var valid_611351 = path.getOrDefault("apiId")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "apiId", valid_611351
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_CreateAuthorizer_611348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_CreateAuthorizer_611348; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_611362 = newJObject()
  var body_611363 = newJObject()
  add(path_611362, "apiId", newJString(apiId))
  if body != nil:
    body_611363 = body
  result = call_611361.call(path_611362, nil, nil, nil, body_611363)

var createAuthorizer* = Call_CreateAuthorizer_611348(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_611349,
    base: "/", url: url_CreateAuthorizer_611350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_611331 = ref object of OpenApiRestCall_610658
proc url_GetAuthorizers_611333(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizers_611332(path: JsonNode; query: JsonNode;
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
  var valid_611334 = path.getOrDefault("apiId")
  valid_611334 = validateParameter(valid_611334, JString, required = true,
                                 default = nil)
  if valid_611334 != nil:
    section.add "apiId", valid_611334
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611335 = query.getOrDefault("nextToken")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "nextToken", valid_611335
  var valid_611336 = query.getOrDefault("maxResults")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "maxResults", valid_611336
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
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Date")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Date", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Credential")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Credential", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611344: Call_GetAuthorizers_611331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_611344.validator(path, query, header, formData, body)
  let scheme = call_611344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611344.url(scheme.get, call_611344.host, call_611344.base,
                         call_611344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611344, url, valid)

proc call*(call_611345: Call_GetAuthorizers_611331; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611346 = newJObject()
  var query_611347 = newJObject()
  add(query_611347, "nextToken", newJString(nextToken))
  add(path_611346, "apiId", newJString(apiId))
  add(query_611347, "maxResults", newJString(maxResults))
  result = call_611345.call(path_611346, query_611347, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_611331(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_611332,
    base: "/", url: url_GetAuthorizers_611333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_611381 = ref object of OpenApiRestCall_610658
proc url_CreateDeployment_611383(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_611382(path: JsonNode; query: JsonNode;
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
  var valid_611384 = path.getOrDefault("apiId")
  valid_611384 = validateParameter(valid_611384, JString, required = true,
                                 default = nil)
  if valid_611384 != nil:
    section.add "apiId", valid_611384
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
  var valid_611385 = header.getOrDefault("X-Amz-Signature")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Signature", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Content-Sha256", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Date")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Date", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Credential")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Credential", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Security-Token")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Security-Token", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Algorithm")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Algorithm", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-SignedHeaders", valid_611391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611393: Call_CreateDeployment_611381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_611393.validator(path, query, header, formData, body)
  let scheme = call_611393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611393.url(scheme.get, call_611393.host, call_611393.base,
                         call_611393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611393, url, valid)

proc call*(call_611394: Call_CreateDeployment_611381; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_611395 = newJObject()
  var body_611396 = newJObject()
  add(path_611395, "apiId", newJString(apiId))
  if body != nil:
    body_611396 = body
  result = call_611394.call(path_611395, nil, nil, nil, body_611396)

var createDeployment* = Call_CreateDeployment_611381(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_611382,
    base: "/", url: url_CreateDeployment_611383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_611364 = ref object of OpenApiRestCall_610658
proc url_GetDeployments_611366(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployments_611365(path: JsonNode; query: JsonNode;
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
  var valid_611367 = path.getOrDefault("apiId")
  valid_611367 = validateParameter(valid_611367, JString, required = true,
                                 default = nil)
  if valid_611367 != nil:
    section.add "apiId", valid_611367
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611368 = query.getOrDefault("nextToken")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "nextToken", valid_611368
  var valid_611369 = query.getOrDefault("maxResults")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "maxResults", valid_611369
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
  var valid_611370 = header.getOrDefault("X-Amz-Signature")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Signature", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Content-Sha256", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Date")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Date", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Credential")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Credential", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Security-Token")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Security-Token", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Algorithm")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Algorithm", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-SignedHeaders", valid_611376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611377: Call_GetDeployments_611364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_611377.validator(path, query, header, formData, body)
  let scheme = call_611377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611377.url(scheme.get, call_611377.host, call_611377.base,
                         call_611377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611377, url, valid)

proc call*(call_611378: Call_GetDeployments_611364; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611379 = newJObject()
  var query_611380 = newJObject()
  add(query_611380, "nextToken", newJString(nextToken))
  add(path_611379, "apiId", newJString(apiId))
  add(query_611380, "maxResults", newJString(maxResults))
  result = call_611378.call(path_611379, query_611380, nil, nil, nil)

var getDeployments* = Call_GetDeployments_611364(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_611365,
    base: "/", url: url_GetDeployments_611366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_611412 = ref object of OpenApiRestCall_610658
proc url_CreateDomainName_611414(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainName_611413(path: JsonNode; query: JsonNode;
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611423: Call_CreateDomainName_611412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_611423.validator(path, query, header, formData, body)
  let scheme = call_611423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611423.url(scheme.get, call_611423.host, call_611423.base,
                         call_611423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611423, url, valid)

proc call*(call_611424: Call_CreateDomainName_611412; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_611425 = newJObject()
  if body != nil:
    body_611425 = body
  result = call_611424.call(nil, nil, nil, nil, body_611425)

var createDomainName* = Call_CreateDomainName_611412(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_611413,
    base: "/", url: url_CreateDomainName_611414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_611397 = ref object of OpenApiRestCall_610658
proc url_GetDomainNames_611399(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainNames_611398(path: JsonNode; query: JsonNode;
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
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611400 = query.getOrDefault("nextToken")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "nextToken", valid_611400
  var valid_611401 = query.getOrDefault("maxResults")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "maxResults", valid_611401
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
  var valid_611402 = header.getOrDefault("X-Amz-Signature")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Signature", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Content-Sha256", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Date")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Date", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Credential")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Credential", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Security-Token")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Security-Token", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Algorithm")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Algorithm", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-SignedHeaders", valid_611408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611409: Call_GetDomainNames_611397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_611409.validator(path, query, header, formData, body)
  let scheme = call_611409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611409.url(scheme.get, call_611409.host, call_611409.base,
                         call_611409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611409, url, valid)

proc call*(call_611410: Call_GetDomainNames_611397; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_611411 = newJObject()
  add(query_611411, "nextToken", newJString(nextToken))
  add(query_611411, "maxResults", newJString(maxResults))
  result = call_611410.call(nil, query_611411, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_611397(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_611398, base: "/",
    url: url_GetDomainNames_611399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_611443 = ref object of OpenApiRestCall_610658
proc url_CreateIntegration_611445(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegration_611444(path: JsonNode; query: JsonNode;
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
  var valid_611446 = path.getOrDefault("apiId")
  valid_611446 = validateParameter(valid_611446, JString, required = true,
                                 default = nil)
  if valid_611446 != nil:
    section.add "apiId", valid_611446
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
  var valid_611447 = header.getOrDefault("X-Amz-Signature")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Signature", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Content-Sha256", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Date")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Date", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Credential")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Credential", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Security-Token")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Security-Token", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Algorithm")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Algorithm", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-SignedHeaders", valid_611453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611455: Call_CreateIntegration_611443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_611455.validator(path, query, header, formData, body)
  let scheme = call_611455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611455.url(scheme.get, call_611455.host, call_611455.base,
                         call_611455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611455, url, valid)

proc call*(call_611456: Call_CreateIntegration_611443; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_611457 = newJObject()
  var body_611458 = newJObject()
  add(path_611457, "apiId", newJString(apiId))
  if body != nil:
    body_611458 = body
  result = call_611456.call(path_611457, nil, nil, nil, body_611458)

var createIntegration* = Call_CreateIntegration_611443(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_611444,
    base: "/", url: url_CreateIntegration_611445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_611426 = ref object of OpenApiRestCall_610658
proc url_GetIntegrations_611428(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrations_611427(path: JsonNode; query: JsonNode;
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
  var valid_611429 = path.getOrDefault("apiId")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "apiId", valid_611429
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611430 = query.getOrDefault("nextToken")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "nextToken", valid_611430
  var valid_611431 = query.getOrDefault("maxResults")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "maxResults", valid_611431
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
  var valid_611432 = header.getOrDefault("X-Amz-Signature")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Signature", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Content-Sha256", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Date")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Date", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Credential")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Credential", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Security-Token")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Security-Token", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Algorithm")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Algorithm", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-SignedHeaders", valid_611438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611439: Call_GetIntegrations_611426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_611439.validator(path, query, header, formData, body)
  let scheme = call_611439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611439.url(scheme.get, call_611439.host, call_611439.base,
                         call_611439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611439, url, valid)

proc call*(call_611440: Call_GetIntegrations_611426; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611441 = newJObject()
  var query_611442 = newJObject()
  add(query_611442, "nextToken", newJString(nextToken))
  add(path_611441, "apiId", newJString(apiId))
  add(query_611442, "maxResults", newJString(maxResults))
  result = call_611440.call(path_611441, query_611442, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_611426(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_611427,
    base: "/", url: url_GetIntegrations_611428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_611477 = ref object of OpenApiRestCall_610658
proc url_CreateIntegrationResponse_611479(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegrationResponse_611478(path: JsonNode; query: JsonNode;
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
  var valid_611480 = path.getOrDefault("apiId")
  valid_611480 = validateParameter(valid_611480, JString, required = true,
                                 default = nil)
  if valid_611480 != nil:
    section.add "apiId", valid_611480
  var valid_611481 = path.getOrDefault("integrationId")
  valid_611481 = validateParameter(valid_611481, JString, required = true,
                                 default = nil)
  if valid_611481 != nil:
    section.add "integrationId", valid_611481
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
  var valid_611482 = header.getOrDefault("X-Amz-Signature")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Signature", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Content-Sha256", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Date")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Date", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Credential")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Credential", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Security-Token")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Security-Token", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Algorithm")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Algorithm", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-SignedHeaders", valid_611488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611490: Call_CreateIntegrationResponse_611477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_611490.validator(path, query, header, formData, body)
  let scheme = call_611490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611490.url(scheme.get, call_611490.host, call_611490.base,
                         call_611490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611490, url, valid)

proc call*(call_611491: Call_CreateIntegrationResponse_611477; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_611492 = newJObject()
  var body_611493 = newJObject()
  add(path_611492, "apiId", newJString(apiId))
  add(path_611492, "integrationId", newJString(integrationId))
  if body != nil:
    body_611493 = body
  result = call_611491.call(path_611492, nil, nil, nil, body_611493)

var createIntegrationResponse* = Call_CreateIntegrationResponse_611477(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_611478, base: "/",
    url: url_CreateIntegrationResponse_611479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_611459 = ref object of OpenApiRestCall_610658
proc url_GetIntegrationResponses_611461(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponses_611460(path: JsonNode; query: JsonNode;
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
  var valid_611462 = path.getOrDefault("apiId")
  valid_611462 = validateParameter(valid_611462, JString, required = true,
                                 default = nil)
  if valid_611462 != nil:
    section.add "apiId", valid_611462
  var valid_611463 = path.getOrDefault("integrationId")
  valid_611463 = validateParameter(valid_611463, JString, required = true,
                                 default = nil)
  if valid_611463 != nil:
    section.add "integrationId", valid_611463
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611464 = query.getOrDefault("nextToken")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "nextToken", valid_611464
  var valid_611465 = query.getOrDefault("maxResults")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "maxResults", valid_611465
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
  var valid_611466 = header.getOrDefault("X-Amz-Signature")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Signature", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Content-Sha256", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Date")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Date", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Credential")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Credential", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Security-Token")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Security-Token", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Algorithm")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Algorithm", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-SignedHeaders", valid_611472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611473: Call_GetIntegrationResponses_611459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_611473.validator(path, query, header, formData, body)
  let scheme = call_611473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611473.url(scheme.get, call_611473.host, call_611473.base,
                         call_611473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611473, url, valid)

proc call*(call_611474: Call_GetIntegrationResponses_611459; apiId: string;
          integrationId: string; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrationResponses
  ## Gets the IntegrationResponses for an Integration.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611475 = newJObject()
  var query_611476 = newJObject()
  add(query_611476, "nextToken", newJString(nextToken))
  add(path_611475, "apiId", newJString(apiId))
  add(path_611475, "integrationId", newJString(integrationId))
  add(query_611476, "maxResults", newJString(maxResults))
  result = call_611474.call(path_611475, query_611476, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_611459(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_611460, base: "/",
    url: url_GetIntegrationResponses_611461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_611511 = ref object of OpenApiRestCall_610658
proc url_CreateModel_611513(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateModel_611512(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611514 = path.getOrDefault("apiId")
  valid_611514 = validateParameter(valid_611514, JString, required = true,
                                 default = nil)
  if valid_611514 != nil:
    section.add "apiId", valid_611514
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
  var valid_611515 = header.getOrDefault("X-Amz-Signature")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Signature", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Content-Sha256", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Date")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Date", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Credential")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Credential", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Security-Token")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Security-Token", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Algorithm")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Algorithm", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-SignedHeaders", valid_611521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611523: Call_CreateModel_611511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_611523.validator(path, query, header, formData, body)
  let scheme = call_611523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611523.url(scheme.get, call_611523.host, call_611523.base,
                         call_611523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611523, url, valid)

proc call*(call_611524: Call_CreateModel_611511; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_611525 = newJObject()
  var body_611526 = newJObject()
  add(path_611525, "apiId", newJString(apiId))
  if body != nil:
    body_611526 = body
  result = call_611524.call(path_611525, nil, nil, nil, body_611526)

var createModel* = Call_CreateModel_611511(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_611512,
                                        base: "/", url: url_CreateModel_611513,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_611494 = ref object of OpenApiRestCall_610658
proc url_GetModels_611496(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModels_611495(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611497 = path.getOrDefault("apiId")
  valid_611497 = validateParameter(valid_611497, JString, required = true,
                                 default = nil)
  if valid_611497 != nil:
    section.add "apiId", valid_611497
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611498 = query.getOrDefault("nextToken")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "nextToken", valid_611498
  var valid_611499 = query.getOrDefault("maxResults")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "maxResults", valid_611499
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
  var valid_611500 = header.getOrDefault("X-Amz-Signature")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Signature", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Content-Sha256", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Date")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Date", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Credential")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Credential", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Security-Token")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Security-Token", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Algorithm")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Algorithm", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-SignedHeaders", valid_611506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611507: Call_GetModels_611494; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_611507.validator(path, query, header, formData, body)
  let scheme = call_611507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611507.url(scheme.get, call_611507.host, call_611507.base,
                         call_611507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611507, url, valid)

proc call*(call_611508: Call_GetModels_611494; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611509 = newJObject()
  var query_611510 = newJObject()
  add(query_611510, "nextToken", newJString(nextToken))
  add(path_611509, "apiId", newJString(apiId))
  add(query_611510, "maxResults", newJString(maxResults))
  result = call_611508.call(path_611509, query_611510, nil, nil, nil)

var getModels* = Call_GetModels_611494(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_611495,
                                    base: "/", url: url_GetModels_611496,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_611544 = ref object of OpenApiRestCall_610658
proc url_CreateRoute_611546(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoute_611545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611547 = path.getOrDefault("apiId")
  valid_611547 = validateParameter(valid_611547, JString, required = true,
                                 default = nil)
  if valid_611547 != nil:
    section.add "apiId", valid_611547
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611556: Call_CreateRoute_611544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_611556.validator(path, query, header, formData, body)
  let scheme = call_611556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611556.url(scheme.get, call_611556.host, call_611556.base,
                         call_611556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611556, url, valid)

proc call*(call_611557: Call_CreateRoute_611544; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_611558 = newJObject()
  var body_611559 = newJObject()
  add(path_611558, "apiId", newJString(apiId))
  if body != nil:
    body_611559 = body
  result = call_611557.call(path_611558, nil, nil, nil, body_611559)

var createRoute* = Call_CreateRoute_611544(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_611545,
                                        base: "/", url: url_CreateRoute_611546,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_611527 = ref object of OpenApiRestCall_610658
proc url_GetRoutes_611529(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoutes_611528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611530 = path.getOrDefault("apiId")
  valid_611530 = validateParameter(valid_611530, JString, required = true,
                                 default = nil)
  if valid_611530 != nil:
    section.add "apiId", valid_611530
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611531 = query.getOrDefault("nextToken")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "nextToken", valid_611531
  var valid_611532 = query.getOrDefault("maxResults")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "maxResults", valid_611532
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
  var valid_611533 = header.getOrDefault("X-Amz-Signature")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Signature", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Content-Sha256", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Date")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Date", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Credential")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Credential", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Security-Token")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Security-Token", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Algorithm")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Algorithm", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-SignedHeaders", valid_611539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611540: Call_GetRoutes_611527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_611540.validator(path, query, header, formData, body)
  let scheme = call_611540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611540.url(scheme.get, call_611540.host, call_611540.base,
                         call_611540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611540, url, valid)

proc call*(call_611541: Call_GetRoutes_611527; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611542 = newJObject()
  var query_611543 = newJObject()
  add(query_611543, "nextToken", newJString(nextToken))
  add(path_611542, "apiId", newJString(apiId))
  add(query_611543, "maxResults", newJString(maxResults))
  result = call_611541.call(path_611542, query_611543, nil, nil, nil)

var getRoutes* = Call_GetRoutes_611527(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_611528,
                                    base: "/", url: url_GetRoutes_611529,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_611578 = ref object of OpenApiRestCall_610658
proc url_CreateRouteResponse_611580(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRouteResponse_611579(path: JsonNode; query: JsonNode;
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
  var valid_611581 = path.getOrDefault("apiId")
  valid_611581 = validateParameter(valid_611581, JString, required = true,
                                 default = nil)
  if valid_611581 != nil:
    section.add "apiId", valid_611581
  var valid_611582 = path.getOrDefault("routeId")
  valid_611582 = validateParameter(valid_611582, JString, required = true,
                                 default = nil)
  if valid_611582 != nil:
    section.add "routeId", valid_611582
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
  var valid_611583 = header.getOrDefault("X-Amz-Signature")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Signature", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Content-Sha256", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Date")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Date", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Credential")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Credential", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Security-Token")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Security-Token", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Algorithm")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Algorithm", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-SignedHeaders", valid_611589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611591: Call_CreateRouteResponse_611578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_611591.validator(path, query, header, formData, body)
  let scheme = call_611591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611591.url(scheme.get, call_611591.host, call_611591.base,
                         call_611591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611591, url, valid)

proc call*(call_611592: Call_CreateRouteResponse_611578; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_611593 = newJObject()
  var body_611594 = newJObject()
  add(path_611593, "apiId", newJString(apiId))
  if body != nil:
    body_611594 = body
  add(path_611593, "routeId", newJString(routeId))
  result = call_611592.call(path_611593, nil, nil, nil, body_611594)

var createRouteResponse* = Call_CreateRouteResponse_611578(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_611579, base: "/",
    url: url_CreateRouteResponse_611580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_611560 = ref object of OpenApiRestCall_610658
proc url_GetRouteResponses_611562(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponses_611561(path: JsonNode; query: JsonNode;
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
  var valid_611563 = path.getOrDefault("apiId")
  valid_611563 = validateParameter(valid_611563, JString, required = true,
                                 default = nil)
  if valid_611563 != nil:
    section.add "apiId", valid_611563
  var valid_611564 = path.getOrDefault("routeId")
  valid_611564 = validateParameter(valid_611564, JString, required = true,
                                 default = nil)
  if valid_611564 != nil:
    section.add "routeId", valid_611564
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611565 = query.getOrDefault("nextToken")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "nextToken", valid_611565
  var valid_611566 = query.getOrDefault("maxResults")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "maxResults", valid_611566
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

proc call*(call_611574: Call_GetRouteResponses_611560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_611574.validator(path, query, header, formData, body)
  let scheme = call_611574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611574.url(scheme.get, call_611574.host, call_611574.base,
                         call_611574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611574, url, valid)

proc call*(call_611575: Call_GetRouteResponses_611560; apiId: string;
          routeId: string; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getRouteResponses
  ## Gets the RouteResponses for a Route.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611576 = newJObject()
  var query_611577 = newJObject()
  add(query_611577, "nextToken", newJString(nextToken))
  add(path_611576, "apiId", newJString(apiId))
  add(path_611576, "routeId", newJString(routeId))
  add(query_611577, "maxResults", newJString(maxResults))
  result = call_611575.call(path_611576, query_611577, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_611560(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_611561, base: "/",
    url: url_GetRouteResponses_611562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_611612 = ref object of OpenApiRestCall_610658
proc url_CreateStage_611614(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateStage_611613(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611615 = path.getOrDefault("apiId")
  valid_611615 = validateParameter(valid_611615, JString, required = true,
                                 default = nil)
  if valid_611615 != nil:
    section.add "apiId", valid_611615
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

proc call*(call_611624: Call_CreateStage_611612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_611624.validator(path, query, header, formData, body)
  let scheme = call_611624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611624.url(scheme.get, call_611624.host, call_611624.base,
                         call_611624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611624, url, valid)

proc call*(call_611625: Call_CreateStage_611612; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_611626 = newJObject()
  var body_611627 = newJObject()
  add(path_611626, "apiId", newJString(apiId))
  if body != nil:
    body_611627 = body
  result = call_611625.call(path_611626, nil, nil, nil, body_611627)

var createStage* = Call_CreateStage_611612(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_611613,
                                        base: "/", url: url_CreateStage_611614,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_611595 = ref object of OpenApiRestCall_610658
proc url_GetStages_611597(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStages_611596(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611598 = path.getOrDefault("apiId")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = nil)
  if valid_611598 != nil:
    section.add "apiId", valid_611598
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_611599 = query.getOrDefault("nextToken")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "nextToken", valid_611599
  var valid_611600 = query.getOrDefault("maxResults")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "maxResults", valid_611600
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
  var valid_611601 = header.getOrDefault("X-Amz-Signature")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Signature", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Content-Sha256", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Date")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Date", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Credential")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Credential", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Security-Token")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Security-Token", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Algorithm")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Algorithm", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-SignedHeaders", valid_611607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611608: Call_GetStages_611595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_611608.validator(path, query, header, formData, body)
  let scheme = call_611608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611608.url(scheme.get, call_611608.host, call_611608.base,
                         call_611608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611608, url, valid)

proc call*(call_611609: Call_GetStages_611595; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_611610 = newJObject()
  var query_611611 = newJObject()
  add(query_611611, "nextToken", newJString(nextToken))
  add(path_611610, "apiId", newJString(apiId))
  add(query_611611, "maxResults", newJString(maxResults))
  result = call_611609.call(path_611610, query_611611, nil, nil, nil)

var getStages* = Call_GetStages_611595(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_611596,
                                    base: "/", url: url_GetStages_611597,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReimportApi_611642 = ref object of OpenApiRestCall_610658
proc url_ReimportApi_611644(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReimportApi_611643(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Puts an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611645 = path.getOrDefault("apiId")
  valid_611645 = validateParameter(valid_611645, JString, required = true,
                                 default = nil)
  if valid_611645 != nil:
    section.add "apiId", valid_611645
  result.add "path", section
  ## parameters in `query` object:
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  section = newJObject()
  var valid_611646 = query.getOrDefault("failOnWarnings")
  valid_611646 = validateParameter(valid_611646, JBool, required = false, default = nil)
  if valid_611646 != nil:
    section.add "failOnWarnings", valid_611646
  var valid_611647 = query.getOrDefault("basepath")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "basepath", valid_611647
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
  var valid_611648 = header.getOrDefault("X-Amz-Signature")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Signature", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Content-Sha256", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Date")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Date", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Credential")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Credential", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Security-Token")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Security-Token", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Algorithm")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Algorithm", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-SignedHeaders", valid_611654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611656: Call_ReimportApi_611642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts an Api resource.
  ## 
  let valid = call_611656.validator(path, query, header, formData, body)
  let scheme = call_611656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611656.url(scheme.get, call_611656.host, call_611656.base,
                         call_611656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611656, url, valid)

proc call*(call_611657: Call_ReimportApi_611642; apiId: string; body: JsonNode;
          failOnWarnings: bool = false; basepath: string = ""): Recallable =
  ## reimportApi
  ## Puts an Api resource.
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  var path_611658 = newJObject()
  var query_611659 = newJObject()
  var body_611660 = newJObject()
  add(query_611659, "failOnWarnings", newJBool(failOnWarnings))
  add(path_611658, "apiId", newJString(apiId))
  if body != nil:
    body_611660 = body
  add(query_611659, "basepath", newJString(basepath))
  result = call_611657.call(path_611658, query_611659, nil, nil, body_611660)

var reimportApi* = Call_ReimportApi_611642(name: "reimportApi",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}",
                                        validator: validate_ReimportApi_611643,
                                        base: "/", url: url_ReimportApi_611644,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_611628 = ref object of OpenApiRestCall_610658
proc url_GetApi_611630(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApi_611629(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611631 = path.getOrDefault("apiId")
  valid_611631 = validateParameter(valid_611631, JString, required = true,
                                 default = nil)
  if valid_611631 != nil:
    section.add "apiId", valid_611631
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
  var valid_611632 = header.getOrDefault("X-Amz-Signature")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Signature", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Content-Sha256", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Date")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Date", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Credential")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Credential", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Security-Token")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Security-Token", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Algorithm")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Algorithm", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-SignedHeaders", valid_611638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611639: Call_GetApi_611628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_611639.validator(path, query, header, formData, body)
  let scheme = call_611639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611639.url(scheme.get, call_611639.host, call_611639.base,
                         call_611639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611639, url, valid)

proc call*(call_611640: Call_GetApi_611628; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_611641 = newJObject()
  add(path_611641, "apiId", newJString(apiId))
  result = call_611640.call(path_611641, nil, nil, nil, nil)

var getApi* = Call_GetApi_611628(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_611629, base: "/",
                              url: url_GetApi_611630,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_611675 = ref object of OpenApiRestCall_610658
proc url_UpdateApi_611677(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApi_611676(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611678 = path.getOrDefault("apiId")
  valid_611678 = validateParameter(valid_611678, JString, required = true,
                                 default = nil)
  if valid_611678 != nil:
    section.add "apiId", valid_611678
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
  var valid_611679 = header.getOrDefault("X-Amz-Signature")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Signature", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Content-Sha256", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Date")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Date", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Credential")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Credential", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Security-Token")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Security-Token", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Algorithm")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Algorithm", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-SignedHeaders", valid_611685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611687: Call_UpdateApi_611675; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_611687.validator(path, query, header, formData, body)
  let scheme = call_611687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611687.url(scheme.get, call_611687.host, call_611687.base,
                         call_611687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611687, url, valid)

proc call*(call_611688: Call_UpdateApi_611675; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_611689 = newJObject()
  var body_611690 = newJObject()
  add(path_611689, "apiId", newJString(apiId))
  if body != nil:
    body_611690 = body
  result = call_611688.call(path_611689, nil, nil, nil, body_611690)

var updateApi* = Call_UpdateApi_611675(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_611676,
                                    base: "/", url: url_UpdateApi_611677,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_611661 = ref object of OpenApiRestCall_610658
proc url_DeleteApi_611663(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApi_611662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611664 = path.getOrDefault("apiId")
  valid_611664 = validateParameter(valid_611664, JString, required = true,
                                 default = nil)
  if valid_611664 != nil:
    section.add "apiId", valid_611664
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
  var valid_611665 = header.getOrDefault("X-Amz-Signature")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Signature", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Content-Sha256", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Date")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Date", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Credential")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Credential", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Security-Token")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Security-Token", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Algorithm")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Algorithm", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-SignedHeaders", valid_611671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611672: Call_DeleteApi_611661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_611672.validator(path, query, header, formData, body)
  let scheme = call_611672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611672.url(scheme.get, call_611672.host, call_611672.base,
                         call_611672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611672, url, valid)

proc call*(call_611673: Call_DeleteApi_611661; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_611674 = newJObject()
  add(path_611674, "apiId", newJString(apiId))
  result = call_611673.call(path_611674, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_611661(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_611662,
                                    base: "/", url: url_DeleteApi_611663,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_611691 = ref object of OpenApiRestCall_610658
proc url_GetApiMapping_611693(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMapping_611692(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an API mapping.
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
  var valid_611694 = path.getOrDefault("apiMappingId")
  valid_611694 = validateParameter(valid_611694, JString, required = true,
                                 default = nil)
  if valid_611694 != nil:
    section.add "apiMappingId", valid_611694
  var valid_611695 = path.getOrDefault("domainName")
  valid_611695 = validateParameter(valid_611695, JString, required = true,
                                 default = nil)
  if valid_611695 != nil:
    section.add "domainName", valid_611695
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
  var valid_611696 = header.getOrDefault("X-Amz-Signature")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Signature", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Content-Sha256", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Date")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Date", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Credential")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Credential", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Security-Token")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Security-Token", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Algorithm")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Algorithm", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-SignedHeaders", valid_611702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611703: Call_GetApiMapping_611691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an API mapping.
  ## 
  let valid = call_611703.validator(path, query, header, formData, body)
  let scheme = call_611703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611703.url(scheme.get, call_611703.host, call_611703.base,
                         call_611703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611703, url, valid)

proc call*(call_611704: Call_GetApiMapping_611691; apiMappingId: string;
          domainName: string): Recallable =
  ## getApiMapping
  ## Gets an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_611705 = newJObject()
  add(path_611705, "apiMappingId", newJString(apiMappingId))
  add(path_611705, "domainName", newJString(domainName))
  result = call_611704.call(path_611705, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_611691(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_611692, base: "/", url: url_GetApiMapping_611693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_611721 = ref object of OpenApiRestCall_610658
proc url_UpdateApiMapping_611723(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiMapping_611722(path: JsonNode; query: JsonNode;
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
  var valid_611724 = path.getOrDefault("apiMappingId")
  valid_611724 = validateParameter(valid_611724, JString, required = true,
                                 default = nil)
  if valid_611724 != nil:
    section.add "apiMappingId", valid_611724
  var valid_611725 = path.getOrDefault("domainName")
  valid_611725 = validateParameter(valid_611725, JString, required = true,
                                 default = nil)
  if valid_611725 != nil:
    section.add "domainName", valid_611725
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
  var valid_611726 = header.getOrDefault("X-Amz-Signature")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Signature", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Content-Sha256", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Date")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Date", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Credential")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Credential", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Security-Token")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Security-Token", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-Algorithm")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Algorithm", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-SignedHeaders", valid_611732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611734: Call_UpdateApiMapping_611721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_611734.validator(path, query, header, formData, body)
  let scheme = call_611734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611734.url(scheme.get, call_611734.host, call_611734.base,
                         call_611734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611734, url, valid)

proc call*(call_611735: Call_UpdateApiMapping_611721; apiMappingId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_611736 = newJObject()
  var body_611737 = newJObject()
  add(path_611736, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_611737 = body
  add(path_611736, "domainName", newJString(domainName))
  result = call_611735.call(path_611736, nil, nil, nil, body_611737)

var updateApiMapping* = Call_UpdateApiMapping_611721(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_611722, base: "/",
    url: url_UpdateApiMapping_611723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_611706 = ref object of OpenApiRestCall_610658
proc url_DeleteApiMapping_611708(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiMapping_611707(path: JsonNode; query: JsonNode;
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
  var valid_611709 = path.getOrDefault("apiMappingId")
  valid_611709 = validateParameter(valid_611709, JString, required = true,
                                 default = nil)
  if valid_611709 != nil:
    section.add "apiMappingId", valid_611709
  var valid_611710 = path.getOrDefault("domainName")
  valid_611710 = validateParameter(valid_611710, JString, required = true,
                                 default = nil)
  if valid_611710 != nil:
    section.add "domainName", valid_611710
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
  var valid_611711 = header.getOrDefault("X-Amz-Signature")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Signature", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Content-Sha256", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Date")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Date", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Credential")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Credential", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Security-Token")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Security-Token", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Algorithm")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Algorithm", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-SignedHeaders", valid_611717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611718: Call_DeleteApiMapping_611706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_611718.validator(path, query, header, formData, body)
  let scheme = call_611718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611718.url(scheme.get, call_611718.host, call_611718.base,
                         call_611718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611718, url, valid)

proc call*(call_611719: Call_DeleteApiMapping_611706; apiMappingId: string;
          domainName: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_611720 = newJObject()
  add(path_611720, "apiMappingId", newJString(apiMappingId))
  add(path_611720, "domainName", newJString(domainName))
  result = call_611719.call(path_611720, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_611706(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_611707, base: "/",
    url: url_DeleteApiMapping_611708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_611738 = ref object of OpenApiRestCall_610658
proc url_GetAuthorizer_611740(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizer_611739(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611741 = path.getOrDefault("apiId")
  valid_611741 = validateParameter(valid_611741, JString, required = true,
                                 default = nil)
  if valid_611741 != nil:
    section.add "apiId", valid_611741
  var valid_611742 = path.getOrDefault("authorizerId")
  valid_611742 = validateParameter(valid_611742, JString, required = true,
                                 default = nil)
  if valid_611742 != nil:
    section.add "authorizerId", valid_611742
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
  var valid_611743 = header.getOrDefault("X-Amz-Signature")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Signature", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Content-Sha256", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Date")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Date", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Credential")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Credential", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Security-Token")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Security-Token", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Algorithm")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Algorithm", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-SignedHeaders", valid_611749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611750: Call_GetAuthorizer_611738; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_611750.validator(path, query, header, formData, body)
  let scheme = call_611750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611750.url(scheme.get, call_611750.host, call_611750.base,
                         call_611750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611750, url, valid)

proc call*(call_611751: Call_GetAuthorizer_611738; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_611752 = newJObject()
  add(path_611752, "apiId", newJString(apiId))
  add(path_611752, "authorizerId", newJString(authorizerId))
  result = call_611751.call(path_611752, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_611738(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_611739, base: "/", url: url_GetAuthorizer_611740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_611768 = ref object of OpenApiRestCall_610658
proc url_UpdateAuthorizer_611770(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAuthorizer_611769(path: JsonNode; query: JsonNode;
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
  var valid_611771 = path.getOrDefault("apiId")
  valid_611771 = validateParameter(valid_611771, JString, required = true,
                                 default = nil)
  if valid_611771 != nil:
    section.add "apiId", valid_611771
  var valid_611772 = path.getOrDefault("authorizerId")
  valid_611772 = validateParameter(valid_611772, JString, required = true,
                                 default = nil)
  if valid_611772 != nil:
    section.add "authorizerId", valid_611772
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
  var valid_611773 = header.getOrDefault("X-Amz-Signature")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Signature", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Content-Sha256", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Date")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Date", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Credential")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Credential", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Security-Token")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Security-Token", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Algorithm")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Algorithm", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-SignedHeaders", valid_611779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611781: Call_UpdateAuthorizer_611768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_611781.validator(path, query, header, formData, body)
  let scheme = call_611781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611781.url(scheme.get, call_611781.host, call_611781.base,
                         call_611781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611781, url, valid)

proc call*(call_611782: Call_UpdateAuthorizer_611768; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_611783 = newJObject()
  var body_611784 = newJObject()
  add(path_611783, "apiId", newJString(apiId))
  add(path_611783, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_611784 = body
  result = call_611782.call(path_611783, nil, nil, nil, body_611784)

var updateAuthorizer* = Call_UpdateAuthorizer_611768(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_611769, base: "/",
    url: url_UpdateAuthorizer_611770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_611753 = ref object of OpenApiRestCall_610658
proc url_DeleteAuthorizer_611755(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAuthorizer_611754(path: JsonNode; query: JsonNode;
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
  var valid_611756 = path.getOrDefault("apiId")
  valid_611756 = validateParameter(valid_611756, JString, required = true,
                                 default = nil)
  if valid_611756 != nil:
    section.add "apiId", valid_611756
  var valid_611757 = path.getOrDefault("authorizerId")
  valid_611757 = validateParameter(valid_611757, JString, required = true,
                                 default = nil)
  if valid_611757 != nil:
    section.add "authorizerId", valid_611757
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
  var valid_611758 = header.getOrDefault("X-Amz-Signature")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Signature", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Content-Sha256", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Date")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Date", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Credential")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Credential", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-Security-Token")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Security-Token", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Algorithm")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Algorithm", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-SignedHeaders", valid_611764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611765: Call_DeleteAuthorizer_611753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_611765.validator(path, query, header, formData, body)
  let scheme = call_611765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611765.url(scheme.get, call_611765.host, call_611765.base,
                         call_611765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611765, url, valid)

proc call*(call_611766: Call_DeleteAuthorizer_611753; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_611767 = newJObject()
  add(path_611767, "apiId", newJString(apiId))
  add(path_611767, "authorizerId", newJString(authorizerId))
  result = call_611766.call(path_611767, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_611753(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_611754, base: "/",
    url: url_DeleteAuthorizer_611755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCorsConfiguration_611785 = ref object of OpenApiRestCall_610658
proc url_DeleteCorsConfiguration_611787(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCorsConfiguration_611786(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a CORS configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611788 = path.getOrDefault("apiId")
  valid_611788 = validateParameter(valid_611788, JString, required = true,
                                 default = nil)
  if valid_611788 != nil:
    section.add "apiId", valid_611788
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
  var valid_611789 = header.getOrDefault("X-Amz-Signature")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Signature", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Content-Sha256", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Date")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Date", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Credential")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Credential", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Security-Token")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Security-Token", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Algorithm")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Algorithm", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-SignedHeaders", valid_611795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611796: Call_DeleteCorsConfiguration_611785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a CORS configuration.
  ## 
  let valid = call_611796.validator(path, query, header, formData, body)
  let scheme = call_611796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611796.url(scheme.get, call_611796.host, call_611796.base,
                         call_611796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611796, url, valid)

proc call*(call_611797: Call_DeleteCorsConfiguration_611785; apiId: string): Recallable =
  ## deleteCorsConfiguration
  ## Deletes a CORS configuration.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_611798 = newJObject()
  add(path_611798, "apiId", newJString(apiId))
  result = call_611797.call(path_611798, nil, nil, nil, nil)

var deleteCorsConfiguration* = Call_DeleteCorsConfiguration_611785(
    name: "deleteCorsConfiguration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/cors",
    validator: validate_DeleteCorsConfiguration_611786, base: "/",
    url: url_DeleteCorsConfiguration_611787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_611799 = ref object of OpenApiRestCall_610658
proc url_GetDeployment_611801(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_611800(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611802 = path.getOrDefault("apiId")
  valid_611802 = validateParameter(valid_611802, JString, required = true,
                                 default = nil)
  if valid_611802 != nil:
    section.add "apiId", valid_611802
  var valid_611803 = path.getOrDefault("deploymentId")
  valid_611803 = validateParameter(valid_611803, JString, required = true,
                                 default = nil)
  if valid_611803 != nil:
    section.add "deploymentId", valid_611803
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
  var valid_611804 = header.getOrDefault("X-Amz-Signature")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Signature", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Content-Sha256", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Date")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Date", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-Credential")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Credential", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-Security-Token")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Security-Token", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Algorithm")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Algorithm", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-SignedHeaders", valid_611810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611811: Call_GetDeployment_611799; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_611811.validator(path, query, header, formData, body)
  let scheme = call_611811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611811.url(scheme.get, call_611811.host, call_611811.base,
                         call_611811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611811, url, valid)

proc call*(call_611812: Call_GetDeployment_611799; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_611813 = newJObject()
  add(path_611813, "apiId", newJString(apiId))
  add(path_611813, "deploymentId", newJString(deploymentId))
  result = call_611812.call(path_611813, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_611799(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_611800, base: "/", url: url_GetDeployment_611801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_611829 = ref object of OpenApiRestCall_610658
proc url_UpdateDeployment_611831(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeployment_611830(path: JsonNode; query: JsonNode;
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
  var valid_611832 = path.getOrDefault("apiId")
  valid_611832 = validateParameter(valid_611832, JString, required = true,
                                 default = nil)
  if valid_611832 != nil:
    section.add "apiId", valid_611832
  var valid_611833 = path.getOrDefault("deploymentId")
  valid_611833 = validateParameter(valid_611833, JString, required = true,
                                 default = nil)
  if valid_611833 != nil:
    section.add "deploymentId", valid_611833
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
  var valid_611834 = header.getOrDefault("X-Amz-Signature")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Signature", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Content-Sha256", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Date")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Date", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-Credential")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Credential", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-Security-Token")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-Security-Token", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Algorithm")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Algorithm", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-SignedHeaders", valid_611840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611842: Call_UpdateDeployment_611829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_611842.validator(path, query, header, formData, body)
  let scheme = call_611842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611842.url(scheme.get, call_611842.host, call_611842.base,
                         call_611842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611842, url, valid)

proc call*(call_611843: Call_UpdateDeployment_611829; apiId: string; body: JsonNode;
          deploymentId: string): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_611844 = newJObject()
  var body_611845 = newJObject()
  add(path_611844, "apiId", newJString(apiId))
  if body != nil:
    body_611845 = body
  add(path_611844, "deploymentId", newJString(deploymentId))
  result = call_611843.call(path_611844, nil, nil, nil, body_611845)

var updateDeployment* = Call_UpdateDeployment_611829(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_611830, base: "/",
    url: url_UpdateDeployment_611831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_611814 = ref object of OpenApiRestCall_610658
proc url_DeleteDeployment_611816(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeployment_611815(path: JsonNode; query: JsonNode;
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
  var valid_611817 = path.getOrDefault("apiId")
  valid_611817 = validateParameter(valid_611817, JString, required = true,
                                 default = nil)
  if valid_611817 != nil:
    section.add "apiId", valid_611817
  var valid_611818 = path.getOrDefault("deploymentId")
  valid_611818 = validateParameter(valid_611818, JString, required = true,
                                 default = nil)
  if valid_611818 != nil:
    section.add "deploymentId", valid_611818
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
  var valid_611819 = header.getOrDefault("X-Amz-Signature")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Signature", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Content-Sha256", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Date")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Date", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-Credential")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-Credential", valid_611822
  var valid_611823 = header.getOrDefault("X-Amz-Security-Token")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Security-Token", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Algorithm")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Algorithm", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-SignedHeaders", valid_611825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611826: Call_DeleteDeployment_611814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_611826.validator(path, query, header, formData, body)
  let scheme = call_611826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611826.url(scheme.get, call_611826.host, call_611826.base,
                         call_611826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611826, url, valid)

proc call*(call_611827: Call_DeleteDeployment_611814; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_611828 = newJObject()
  add(path_611828, "apiId", newJString(apiId))
  add(path_611828, "deploymentId", newJString(deploymentId))
  result = call_611827.call(path_611828, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_611814(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_611815, base: "/",
    url: url_DeleteDeployment_611816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_611846 = ref object of OpenApiRestCall_610658
proc url_GetDomainName_611848(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainName_611847(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611849 = path.getOrDefault("domainName")
  valid_611849 = validateParameter(valid_611849, JString, required = true,
                                 default = nil)
  if valid_611849 != nil:
    section.add "domainName", valid_611849
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
  var valid_611850 = header.getOrDefault("X-Amz-Signature")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Signature", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Content-Sha256", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Date")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Date", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-Credential")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Credential", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Security-Token")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Security-Token", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Algorithm")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Algorithm", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-SignedHeaders", valid_611856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611857: Call_GetDomainName_611846; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_611857.validator(path, query, header, formData, body)
  let scheme = call_611857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611857.url(scheme.get, call_611857.host, call_611857.base,
                         call_611857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611857, url, valid)

proc call*(call_611858: Call_GetDomainName_611846; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_611859 = newJObject()
  add(path_611859, "domainName", newJString(domainName))
  result = call_611858.call(path_611859, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_611846(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_611847,
    base: "/", url: url_GetDomainName_611848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_611874 = ref object of OpenApiRestCall_610658
proc url_UpdateDomainName_611876(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainName_611875(path: JsonNode; query: JsonNode;
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
  var valid_611877 = path.getOrDefault("domainName")
  valid_611877 = validateParameter(valid_611877, JString, required = true,
                                 default = nil)
  if valid_611877 != nil:
    section.add "domainName", valid_611877
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
  var valid_611878 = header.getOrDefault("X-Amz-Signature")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Signature", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Content-Sha256", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Date")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Date", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Credential")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Credential", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Security-Token")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Security-Token", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Algorithm")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Algorithm", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-SignedHeaders", valid_611884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611886: Call_UpdateDomainName_611874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_611886.validator(path, query, header, formData, body)
  let scheme = call_611886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611886.url(scheme.get, call_611886.host, call_611886.base,
                         call_611886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611886, url, valid)

proc call*(call_611887: Call_UpdateDomainName_611874; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_611888 = newJObject()
  var body_611889 = newJObject()
  if body != nil:
    body_611889 = body
  add(path_611888, "domainName", newJString(domainName))
  result = call_611887.call(path_611888, nil, nil, nil, body_611889)

var updateDomainName* = Call_UpdateDomainName_611874(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_611875,
    base: "/", url: url_UpdateDomainName_611876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_611860 = ref object of OpenApiRestCall_610658
proc url_DeleteDomainName_611862(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainName_611861(path: JsonNode; query: JsonNode;
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
  var valid_611863 = path.getOrDefault("domainName")
  valid_611863 = validateParameter(valid_611863, JString, required = true,
                                 default = nil)
  if valid_611863 != nil:
    section.add "domainName", valid_611863
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
  var valid_611864 = header.getOrDefault("X-Amz-Signature")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Signature", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Content-Sha256", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Date")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Date", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Credential")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Credential", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Security-Token")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Security-Token", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Algorithm")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Algorithm", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-SignedHeaders", valid_611870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611871: Call_DeleteDomainName_611860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_611871.validator(path, query, header, formData, body)
  let scheme = call_611871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611871.url(scheme.get, call_611871.host, call_611871.base,
                         call_611871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611871, url, valid)

proc call*(call_611872: Call_DeleteDomainName_611860; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_611873 = newJObject()
  add(path_611873, "domainName", newJString(domainName))
  result = call_611872.call(path_611873, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_611860(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_611861,
    base: "/", url: url_DeleteDomainName_611862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_611890 = ref object of OpenApiRestCall_610658
proc url_GetIntegration_611892(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegration_611891(path: JsonNode; query: JsonNode;
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
  var valid_611893 = path.getOrDefault("apiId")
  valid_611893 = validateParameter(valid_611893, JString, required = true,
                                 default = nil)
  if valid_611893 != nil:
    section.add "apiId", valid_611893
  var valid_611894 = path.getOrDefault("integrationId")
  valid_611894 = validateParameter(valid_611894, JString, required = true,
                                 default = nil)
  if valid_611894 != nil:
    section.add "integrationId", valid_611894
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
  var valid_611895 = header.getOrDefault("X-Amz-Signature")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Signature", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Content-Sha256", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Date")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Date", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Credential")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Credential", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Security-Token")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Security-Token", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Algorithm")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Algorithm", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-SignedHeaders", valid_611901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611902: Call_GetIntegration_611890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_611902.validator(path, query, header, formData, body)
  let scheme = call_611902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611902.url(scheme.get, call_611902.host, call_611902.base,
                         call_611902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611902, url, valid)

proc call*(call_611903: Call_GetIntegration_611890; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_611904 = newJObject()
  add(path_611904, "apiId", newJString(apiId))
  add(path_611904, "integrationId", newJString(integrationId))
  result = call_611903.call(path_611904, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_611890(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_611891, base: "/", url: url_GetIntegration_611892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_611920 = ref object of OpenApiRestCall_610658
proc url_UpdateIntegration_611922(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegration_611921(path: JsonNode; query: JsonNode;
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
  var valid_611923 = path.getOrDefault("apiId")
  valid_611923 = validateParameter(valid_611923, JString, required = true,
                                 default = nil)
  if valid_611923 != nil:
    section.add "apiId", valid_611923
  var valid_611924 = path.getOrDefault("integrationId")
  valid_611924 = validateParameter(valid_611924, JString, required = true,
                                 default = nil)
  if valid_611924 != nil:
    section.add "integrationId", valid_611924
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
  var valid_611925 = header.getOrDefault("X-Amz-Signature")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Signature", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Content-Sha256", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Date")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Date", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Credential")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Credential", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Security-Token")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Security-Token", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Algorithm")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Algorithm", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-SignedHeaders", valid_611931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611933: Call_UpdateIntegration_611920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_611933.validator(path, query, header, formData, body)
  let scheme = call_611933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611933.url(scheme.get, call_611933.host, call_611933.base,
                         call_611933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611933, url, valid)

proc call*(call_611934: Call_UpdateIntegration_611920; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_611935 = newJObject()
  var body_611936 = newJObject()
  add(path_611935, "apiId", newJString(apiId))
  add(path_611935, "integrationId", newJString(integrationId))
  if body != nil:
    body_611936 = body
  result = call_611934.call(path_611935, nil, nil, nil, body_611936)

var updateIntegration* = Call_UpdateIntegration_611920(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_611921, base: "/",
    url: url_UpdateIntegration_611922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_611905 = ref object of OpenApiRestCall_610658
proc url_DeleteIntegration_611907(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegration_611906(path: JsonNode; query: JsonNode;
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
  var valid_611908 = path.getOrDefault("apiId")
  valid_611908 = validateParameter(valid_611908, JString, required = true,
                                 default = nil)
  if valid_611908 != nil:
    section.add "apiId", valid_611908
  var valid_611909 = path.getOrDefault("integrationId")
  valid_611909 = validateParameter(valid_611909, JString, required = true,
                                 default = nil)
  if valid_611909 != nil:
    section.add "integrationId", valid_611909
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
  var valid_611910 = header.getOrDefault("X-Amz-Signature")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Signature", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Content-Sha256", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Date")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Date", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Credential")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Credential", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Security-Token")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Security-Token", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Algorithm")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Algorithm", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-SignedHeaders", valid_611916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611917: Call_DeleteIntegration_611905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_611917.validator(path, query, header, formData, body)
  let scheme = call_611917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611917.url(scheme.get, call_611917.host, call_611917.base,
                         call_611917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611917, url, valid)

proc call*(call_611918: Call_DeleteIntegration_611905; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_611919 = newJObject()
  add(path_611919, "apiId", newJString(apiId))
  add(path_611919, "integrationId", newJString(integrationId))
  result = call_611918.call(path_611919, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_611905(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_611906, base: "/",
    url: url_DeleteIntegration_611907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_611937 = ref object of OpenApiRestCall_610658
proc url_GetIntegrationResponse_611939(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponse_611938(path: JsonNode; query: JsonNode;
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
  var valid_611940 = path.getOrDefault("integrationResponseId")
  valid_611940 = validateParameter(valid_611940, JString, required = true,
                                 default = nil)
  if valid_611940 != nil:
    section.add "integrationResponseId", valid_611940
  var valid_611941 = path.getOrDefault("apiId")
  valid_611941 = validateParameter(valid_611941, JString, required = true,
                                 default = nil)
  if valid_611941 != nil:
    section.add "apiId", valid_611941
  var valid_611942 = path.getOrDefault("integrationId")
  valid_611942 = validateParameter(valid_611942, JString, required = true,
                                 default = nil)
  if valid_611942 != nil:
    section.add "integrationId", valid_611942
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
  var valid_611943 = header.getOrDefault("X-Amz-Signature")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Signature", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Content-Sha256", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Date")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Date", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Credential")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Credential", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Security-Token")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Security-Token", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Algorithm")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Algorithm", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-SignedHeaders", valid_611949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611950: Call_GetIntegrationResponse_611937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_611950.validator(path, query, header, formData, body)
  let scheme = call_611950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611950.url(scheme.get, call_611950.host, call_611950.base,
                         call_611950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611950, url, valid)

proc call*(call_611951: Call_GetIntegrationResponse_611937;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_611952 = newJObject()
  add(path_611952, "integrationResponseId", newJString(integrationResponseId))
  add(path_611952, "apiId", newJString(apiId))
  add(path_611952, "integrationId", newJString(integrationId))
  result = call_611951.call(path_611952, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_611937(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_611938, base: "/",
    url: url_GetIntegrationResponse_611939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_611969 = ref object of OpenApiRestCall_610658
proc url_UpdateIntegrationResponse_611971(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_611970(path: JsonNode; query: JsonNode;
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
  var valid_611972 = path.getOrDefault("integrationResponseId")
  valid_611972 = validateParameter(valid_611972, JString, required = true,
                                 default = nil)
  if valid_611972 != nil:
    section.add "integrationResponseId", valid_611972
  var valid_611973 = path.getOrDefault("apiId")
  valid_611973 = validateParameter(valid_611973, JString, required = true,
                                 default = nil)
  if valid_611973 != nil:
    section.add "apiId", valid_611973
  var valid_611974 = path.getOrDefault("integrationId")
  valid_611974 = validateParameter(valid_611974, JString, required = true,
                                 default = nil)
  if valid_611974 != nil:
    section.add "integrationId", valid_611974
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
  var valid_611975 = header.getOrDefault("X-Amz-Signature")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Signature", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Content-Sha256", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Date")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Date", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Credential")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Credential", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Security-Token")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Security-Token", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-Algorithm")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-Algorithm", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-SignedHeaders", valid_611981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611983: Call_UpdateIntegrationResponse_611969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_611983.validator(path, query, header, formData, body)
  let scheme = call_611983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611983.url(scheme.get, call_611983.host, call_611983.base,
                         call_611983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611983, url, valid)

proc call*(call_611984: Call_UpdateIntegrationResponse_611969;
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
  var path_611985 = newJObject()
  var body_611986 = newJObject()
  add(path_611985, "integrationResponseId", newJString(integrationResponseId))
  add(path_611985, "apiId", newJString(apiId))
  add(path_611985, "integrationId", newJString(integrationId))
  if body != nil:
    body_611986 = body
  result = call_611984.call(path_611985, nil, nil, nil, body_611986)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_611969(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_611970, base: "/",
    url: url_UpdateIntegrationResponse_611971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_611953 = ref object of OpenApiRestCall_610658
proc url_DeleteIntegrationResponse_611955(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_611954(path: JsonNode; query: JsonNode;
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
  var valid_611956 = path.getOrDefault("integrationResponseId")
  valid_611956 = validateParameter(valid_611956, JString, required = true,
                                 default = nil)
  if valid_611956 != nil:
    section.add "integrationResponseId", valid_611956
  var valid_611957 = path.getOrDefault("apiId")
  valid_611957 = validateParameter(valid_611957, JString, required = true,
                                 default = nil)
  if valid_611957 != nil:
    section.add "apiId", valid_611957
  var valid_611958 = path.getOrDefault("integrationId")
  valid_611958 = validateParameter(valid_611958, JString, required = true,
                                 default = nil)
  if valid_611958 != nil:
    section.add "integrationId", valid_611958
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
  var valid_611959 = header.getOrDefault("X-Amz-Signature")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Signature", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Content-Sha256", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Date")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Date", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Credential")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Credential", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Security-Token")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Security-Token", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-Algorithm")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Algorithm", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-SignedHeaders", valid_611965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611966: Call_DeleteIntegrationResponse_611953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_611966.validator(path, query, header, formData, body)
  let scheme = call_611966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611966.url(scheme.get, call_611966.host, call_611966.base,
                         call_611966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611966, url, valid)

proc call*(call_611967: Call_DeleteIntegrationResponse_611953;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_611968 = newJObject()
  add(path_611968, "integrationResponseId", newJString(integrationResponseId))
  add(path_611968, "apiId", newJString(apiId))
  add(path_611968, "integrationId", newJString(integrationId))
  result = call_611967.call(path_611968, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_611953(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_611954, base: "/",
    url: url_DeleteIntegrationResponse_611955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_611987 = ref object of OpenApiRestCall_610658
proc url_GetModel_611989(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModel_611988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611990 = path.getOrDefault("apiId")
  valid_611990 = validateParameter(valid_611990, JString, required = true,
                                 default = nil)
  if valid_611990 != nil:
    section.add "apiId", valid_611990
  var valid_611991 = path.getOrDefault("modelId")
  valid_611991 = validateParameter(valid_611991, JString, required = true,
                                 default = nil)
  if valid_611991 != nil:
    section.add "modelId", valid_611991
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
  var valid_611992 = header.getOrDefault("X-Amz-Signature")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Signature", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Content-Sha256", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Date")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Date", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-Credential")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Credential", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-Security-Token")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-Security-Token", valid_611996
  var valid_611997 = header.getOrDefault("X-Amz-Algorithm")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Algorithm", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-SignedHeaders", valid_611998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611999: Call_GetModel_611987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_611999.validator(path, query, header, formData, body)
  let scheme = call_611999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611999.url(scheme.get, call_611999.host, call_611999.base,
                         call_611999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611999, url, valid)

proc call*(call_612000: Call_GetModel_611987; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_612001 = newJObject()
  add(path_612001, "apiId", newJString(apiId))
  add(path_612001, "modelId", newJString(modelId))
  result = call_612000.call(path_612001, nil, nil, nil, nil)

var getModel* = Call_GetModel_611987(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_611988, base: "/",
                                  url: url_GetModel_611989,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_612017 = ref object of OpenApiRestCall_610658
proc url_UpdateModel_612019(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateModel_612018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612020 = path.getOrDefault("apiId")
  valid_612020 = validateParameter(valid_612020, JString, required = true,
                                 default = nil)
  if valid_612020 != nil:
    section.add "apiId", valid_612020
  var valid_612021 = path.getOrDefault("modelId")
  valid_612021 = validateParameter(valid_612021, JString, required = true,
                                 default = nil)
  if valid_612021 != nil:
    section.add "modelId", valid_612021
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
  var valid_612022 = header.getOrDefault("X-Amz-Signature")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Signature", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Content-Sha256", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Date")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Date", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Credential")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Credential", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Security-Token")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Security-Token", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Algorithm")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Algorithm", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-SignedHeaders", valid_612028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612030: Call_UpdateModel_612017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_612030.validator(path, query, header, formData, body)
  let scheme = call_612030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612030.url(scheme.get, call_612030.host, call_612030.base,
                         call_612030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612030, url, valid)

proc call*(call_612031: Call_UpdateModel_612017; apiId: string; body: JsonNode;
          modelId: string): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   modelId: string (required)
  ##          : The model ID.
  var path_612032 = newJObject()
  var body_612033 = newJObject()
  add(path_612032, "apiId", newJString(apiId))
  if body != nil:
    body_612033 = body
  add(path_612032, "modelId", newJString(modelId))
  result = call_612031.call(path_612032, nil, nil, nil, body_612033)

var updateModel* = Call_UpdateModel_612017(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_612018,
                                        base: "/", url: url_UpdateModel_612019,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_612002 = ref object of OpenApiRestCall_610658
proc url_DeleteModel_612004(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteModel_612003(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612005 = path.getOrDefault("apiId")
  valid_612005 = validateParameter(valid_612005, JString, required = true,
                                 default = nil)
  if valid_612005 != nil:
    section.add "apiId", valid_612005
  var valid_612006 = path.getOrDefault("modelId")
  valid_612006 = validateParameter(valid_612006, JString, required = true,
                                 default = nil)
  if valid_612006 != nil:
    section.add "modelId", valid_612006
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
  var valid_612007 = header.getOrDefault("X-Amz-Signature")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Signature", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Content-Sha256", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Date")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Date", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Credential")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Credential", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Security-Token")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Security-Token", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-Algorithm")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Algorithm", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-SignedHeaders", valid_612013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612014: Call_DeleteModel_612002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_612014.validator(path, query, header, formData, body)
  let scheme = call_612014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612014.url(scheme.get, call_612014.host, call_612014.base,
                         call_612014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612014, url, valid)

proc call*(call_612015: Call_DeleteModel_612002; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_612016 = newJObject()
  add(path_612016, "apiId", newJString(apiId))
  add(path_612016, "modelId", newJString(modelId))
  result = call_612015.call(path_612016, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_612002(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_612003,
                                        base: "/", url: url_DeleteModel_612004,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_612034 = ref object of OpenApiRestCall_610658
proc url_GetRoute_612036(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoute_612035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612037 = path.getOrDefault("apiId")
  valid_612037 = validateParameter(valid_612037, JString, required = true,
                                 default = nil)
  if valid_612037 != nil:
    section.add "apiId", valid_612037
  var valid_612038 = path.getOrDefault("routeId")
  valid_612038 = validateParameter(valid_612038, JString, required = true,
                                 default = nil)
  if valid_612038 != nil:
    section.add "routeId", valid_612038
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
  var valid_612039 = header.getOrDefault("X-Amz-Signature")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Signature", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-Content-Sha256", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Date")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Date", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Credential")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Credential", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Security-Token")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Security-Token", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Algorithm")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Algorithm", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-SignedHeaders", valid_612045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612046: Call_GetRoute_612034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_612046.validator(path, query, header, formData, body)
  let scheme = call_612046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612046.url(scheme.get, call_612046.host, call_612046.base,
                         call_612046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612046, url, valid)

proc call*(call_612047: Call_GetRoute_612034; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_612048 = newJObject()
  add(path_612048, "apiId", newJString(apiId))
  add(path_612048, "routeId", newJString(routeId))
  result = call_612047.call(path_612048, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_612034(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_612035, base: "/",
                                  url: url_GetRoute_612036,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_612064 = ref object of OpenApiRestCall_610658
proc url_UpdateRoute_612066(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoute_612065(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612067 = path.getOrDefault("apiId")
  valid_612067 = validateParameter(valid_612067, JString, required = true,
                                 default = nil)
  if valid_612067 != nil:
    section.add "apiId", valid_612067
  var valid_612068 = path.getOrDefault("routeId")
  valid_612068 = validateParameter(valid_612068, JString, required = true,
                                 default = nil)
  if valid_612068 != nil:
    section.add "routeId", valid_612068
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
  var valid_612069 = header.getOrDefault("X-Amz-Signature")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Signature", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-Content-Sha256", valid_612070
  var valid_612071 = header.getOrDefault("X-Amz-Date")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-Date", valid_612071
  var valid_612072 = header.getOrDefault("X-Amz-Credential")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "X-Amz-Credential", valid_612072
  var valid_612073 = header.getOrDefault("X-Amz-Security-Token")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "X-Amz-Security-Token", valid_612073
  var valid_612074 = header.getOrDefault("X-Amz-Algorithm")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "X-Amz-Algorithm", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-SignedHeaders", valid_612075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612077: Call_UpdateRoute_612064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_612077.validator(path, query, header, formData, body)
  let scheme = call_612077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612077.url(scheme.get, call_612077.host, call_612077.base,
                         call_612077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612077, url, valid)

proc call*(call_612078: Call_UpdateRoute_612064; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_612079 = newJObject()
  var body_612080 = newJObject()
  add(path_612079, "apiId", newJString(apiId))
  if body != nil:
    body_612080 = body
  add(path_612079, "routeId", newJString(routeId))
  result = call_612078.call(path_612079, nil, nil, nil, body_612080)

var updateRoute* = Call_UpdateRoute_612064(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_612065,
                                        base: "/", url: url_UpdateRoute_612066,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_612049 = ref object of OpenApiRestCall_610658
proc url_DeleteRoute_612051(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoute_612050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612052 = path.getOrDefault("apiId")
  valid_612052 = validateParameter(valid_612052, JString, required = true,
                                 default = nil)
  if valid_612052 != nil:
    section.add "apiId", valid_612052
  var valid_612053 = path.getOrDefault("routeId")
  valid_612053 = validateParameter(valid_612053, JString, required = true,
                                 default = nil)
  if valid_612053 != nil:
    section.add "routeId", valid_612053
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
  var valid_612054 = header.getOrDefault("X-Amz-Signature")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Signature", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-Content-Sha256", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-Date")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Date", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Credential")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Credential", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-Security-Token")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Security-Token", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Algorithm")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Algorithm", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-SignedHeaders", valid_612060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612061: Call_DeleteRoute_612049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_612061.validator(path, query, header, formData, body)
  let scheme = call_612061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612061.url(scheme.get, call_612061.host, call_612061.base,
                         call_612061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612061, url, valid)

proc call*(call_612062: Call_DeleteRoute_612049; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_612063 = newJObject()
  add(path_612063, "apiId", newJString(apiId))
  add(path_612063, "routeId", newJString(routeId))
  result = call_612062.call(path_612063, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_612049(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_612050,
                                        base: "/", url: url_DeleteRoute_612051,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_612081 = ref object of OpenApiRestCall_610658
proc url_GetRouteResponse_612083(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponse_612082(path: JsonNode; query: JsonNode;
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
  var valid_612084 = path.getOrDefault("apiId")
  valid_612084 = validateParameter(valid_612084, JString, required = true,
                                 default = nil)
  if valid_612084 != nil:
    section.add "apiId", valid_612084
  var valid_612085 = path.getOrDefault("routeResponseId")
  valid_612085 = validateParameter(valid_612085, JString, required = true,
                                 default = nil)
  if valid_612085 != nil:
    section.add "routeResponseId", valid_612085
  var valid_612086 = path.getOrDefault("routeId")
  valid_612086 = validateParameter(valid_612086, JString, required = true,
                                 default = nil)
  if valid_612086 != nil:
    section.add "routeId", valid_612086
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
  var valid_612087 = header.getOrDefault("X-Amz-Signature")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "X-Amz-Signature", valid_612087
  var valid_612088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Content-Sha256", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Date")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Date", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Credential")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Credential", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Security-Token")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Security-Token", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Algorithm")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Algorithm", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-SignedHeaders", valid_612093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612094: Call_GetRouteResponse_612081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_612094.validator(path, query, header, formData, body)
  let scheme = call_612094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612094.url(scheme.get, call_612094.host, call_612094.base,
                         call_612094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612094, url, valid)

proc call*(call_612095: Call_GetRouteResponse_612081; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_612096 = newJObject()
  add(path_612096, "apiId", newJString(apiId))
  add(path_612096, "routeResponseId", newJString(routeResponseId))
  add(path_612096, "routeId", newJString(routeId))
  result = call_612095.call(path_612096, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_612081(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_612082, base: "/",
    url: url_GetRouteResponse_612083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_612113 = ref object of OpenApiRestCall_610658
proc url_UpdateRouteResponse_612115(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRouteResponse_612114(path: JsonNode; query: JsonNode;
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
  var valid_612116 = path.getOrDefault("apiId")
  valid_612116 = validateParameter(valid_612116, JString, required = true,
                                 default = nil)
  if valid_612116 != nil:
    section.add "apiId", valid_612116
  var valid_612117 = path.getOrDefault("routeResponseId")
  valid_612117 = validateParameter(valid_612117, JString, required = true,
                                 default = nil)
  if valid_612117 != nil:
    section.add "routeResponseId", valid_612117
  var valid_612118 = path.getOrDefault("routeId")
  valid_612118 = validateParameter(valid_612118, JString, required = true,
                                 default = nil)
  if valid_612118 != nil:
    section.add "routeId", valid_612118
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
  var valid_612119 = header.getOrDefault("X-Amz-Signature")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-Signature", valid_612119
  var valid_612120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "X-Amz-Content-Sha256", valid_612120
  var valid_612121 = header.getOrDefault("X-Amz-Date")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "X-Amz-Date", valid_612121
  var valid_612122 = header.getOrDefault("X-Amz-Credential")
  valid_612122 = validateParameter(valid_612122, JString, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "X-Amz-Credential", valid_612122
  var valid_612123 = header.getOrDefault("X-Amz-Security-Token")
  valid_612123 = validateParameter(valid_612123, JString, required = false,
                                 default = nil)
  if valid_612123 != nil:
    section.add "X-Amz-Security-Token", valid_612123
  var valid_612124 = header.getOrDefault("X-Amz-Algorithm")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-Algorithm", valid_612124
  var valid_612125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "X-Amz-SignedHeaders", valid_612125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612127: Call_UpdateRouteResponse_612113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_612127.validator(path, query, header, formData, body)
  let scheme = call_612127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612127.url(scheme.get, call_612127.host, call_612127.base,
                         call_612127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612127, url, valid)

proc call*(call_612128: Call_UpdateRouteResponse_612113; apiId: string;
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
  var path_612129 = newJObject()
  var body_612130 = newJObject()
  add(path_612129, "apiId", newJString(apiId))
  add(path_612129, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_612130 = body
  add(path_612129, "routeId", newJString(routeId))
  result = call_612128.call(path_612129, nil, nil, nil, body_612130)

var updateRouteResponse* = Call_UpdateRouteResponse_612113(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_612114, base: "/",
    url: url_UpdateRouteResponse_612115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_612097 = ref object of OpenApiRestCall_610658
proc url_DeleteRouteResponse_612099(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteResponse_612098(path: JsonNode; query: JsonNode;
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
  var valid_612100 = path.getOrDefault("apiId")
  valid_612100 = validateParameter(valid_612100, JString, required = true,
                                 default = nil)
  if valid_612100 != nil:
    section.add "apiId", valid_612100
  var valid_612101 = path.getOrDefault("routeResponseId")
  valid_612101 = validateParameter(valid_612101, JString, required = true,
                                 default = nil)
  if valid_612101 != nil:
    section.add "routeResponseId", valid_612101
  var valid_612102 = path.getOrDefault("routeId")
  valid_612102 = validateParameter(valid_612102, JString, required = true,
                                 default = nil)
  if valid_612102 != nil:
    section.add "routeId", valid_612102
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
  var valid_612103 = header.getOrDefault("X-Amz-Signature")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Signature", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Content-Sha256", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Date")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Date", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Credential")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Credential", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Security-Token")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Security-Token", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-Algorithm")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Algorithm", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-SignedHeaders", valid_612109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612110: Call_DeleteRouteResponse_612097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_612110.validator(path, query, header, formData, body)
  let scheme = call_612110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612110.url(scheme.get, call_612110.host, call_612110.base,
                         call_612110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612110, url, valid)

proc call*(call_612111: Call_DeleteRouteResponse_612097; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_612112 = newJObject()
  add(path_612112, "apiId", newJString(apiId))
  add(path_612112, "routeResponseId", newJString(routeResponseId))
  add(path_612112, "routeId", newJString(routeId))
  result = call_612111.call(path_612112, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_612097(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_612098, base: "/",
    url: url_DeleteRouteResponse_612099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteSettings_612131 = ref object of OpenApiRestCall_610658
proc url_DeleteRouteSettings_612133(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  assert "routeKey" in path, "`routeKey` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName"),
               (kind: ConstantSegment, value: "/routesettings/"),
               (kind: VariableSegment, value: "routeKey")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteSettings_612132(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the RouteSettings for a stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   routeKey: JString (required)
  ##           : The route key.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_612134 = path.getOrDefault("stageName")
  valid_612134 = validateParameter(valid_612134, JString, required = true,
                                 default = nil)
  if valid_612134 != nil:
    section.add "stageName", valid_612134
  var valid_612135 = path.getOrDefault("routeKey")
  valid_612135 = validateParameter(valid_612135, JString, required = true,
                                 default = nil)
  if valid_612135 != nil:
    section.add "routeKey", valid_612135
  var valid_612136 = path.getOrDefault("apiId")
  valid_612136 = validateParameter(valid_612136, JString, required = true,
                                 default = nil)
  if valid_612136 != nil:
    section.add "apiId", valid_612136
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
  var valid_612137 = header.getOrDefault("X-Amz-Signature")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Signature", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-Content-Sha256", valid_612138
  var valid_612139 = header.getOrDefault("X-Amz-Date")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Date", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-Credential")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-Credential", valid_612140
  var valid_612141 = header.getOrDefault("X-Amz-Security-Token")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Security-Token", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Algorithm")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Algorithm", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-SignedHeaders", valid_612143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612144: Call_DeleteRouteSettings_612131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the RouteSettings for a stage.
  ## 
  let valid = call_612144.validator(path, query, header, formData, body)
  let scheme = call_612144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612144.url(scheme.get, call_612144.host, call_612144.base,
                         call_612144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612144, url, valid)

proc call*(call_612145: Call_DeleteRouteSettings_612131; stageName: string;
          routeKey: string; apiId: string): Recallable =
  ## deleteRouteSettings
  ## Deletes the RouteSettings for a stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   routeKey: string (required)
  ##           : The route key.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_612146 = newJObject()
  add(path_612146, "stageName", newJString(stageName))
  add(path_612146, "routeKey", newJString(routeKey))
  add(path_612146, "apiId", newJString(apiId))
  result = call_612145.call(path_612146, nil, nil, nil, nil)

var deleteRouteSettings* = Call_DeleteRouteSettings_612131(
    name: "deleteRouteSettings", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}",
    validator: validate_DeleteRouteSettings_612132, base: "/",
    url: url_DeleteRouteSettings_612133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_612147 = ref object of OpenApiRestCall_610658
proc url_GetStage_612149(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStage_612148(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_612150 = path.getOrDefault("stageName")
  valid_612150 = validateParameter(valid_612150, JString, required = true,
                                 default = nil)
  if valid_612150 != nil:
    section.add "stageName", valid_612150
  var valid_612151 = path.getOrDefault("apiId")
  valid_612151 = validateParameter(valid_612151, JString, required = true,
                                 default = nil)
  if valid_612151 != nil:
    section.add "apiId", valid_612151
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
  var valid_612152 = header.getOrDefault("X-Amz-Signature")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Signature", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Content-Sha256", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Date")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Date", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-Credential")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-Credential", valid_612155
  var valid_612156 = header.getOrDefault("X-Amz-Security-Token")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "X-Amz-Security-Token", valid_612156
  var valid_612157 = header.getOrDefault("X-Amz-Algorithm")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "X-Amz-Algorithm", valid_612157
  var valid_612158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612158 = validateParameter(valid_612158, JString, required = false,
                                 default = nil)
  if valid_612158 != nil:
    section.add "X-Amz-SignedHeaders", valid_612158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612159: Call_GetStage_612147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_612159.validator(path, query, header, formData, body)
  let scheme = call_612159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612159.url(scheme.get, call_612159.host, call_612159.base,
                         call_612159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612159, url, valid)

proc call*(call_612160: Call_GetStage_612147; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_612161 = newJObject()
  add(path_612161, "stageName", newJString(stageName))
  add(path_612161, "apiId", newJString(apiId))
  result = call_612160.call(path_612161, nil, nil, nil, nil)

var getStage* = Call_GetStage_612147(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_612148, base: "/",
                                  url: url_GetStage_612149,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_612177 = ref object of OpenApiRestCall_610658
proc url_UpdateStage_612179(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStage_612178(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_612180 = path.getOrDefault("stageName")
  valid_612180 = validateParameter(valid_612180, JString, required = true,
                                 default = nil)
  if valid_612180 != nil:
    section.add "stageName", valid_612180
  var valid_612181 = path.getOrDefault("apiId")
  valid_612181 = validateParameter(valid_612181, JString, required = true,
                                 default = nil)
  if valid_612181 != nil:
    section.add "apiId", valid_612181
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
  var valid_612182 = header.getOrDefault("X-Amz-Signature")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Signature", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Content-Sha256", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-Date")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-Date", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-Credential")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-Credential", valid_612185
  var valid_612186 = header.getOrDefault("X-Amz-Security-Token")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "X-Amz-Security-Token", valid_612186
  var valid_612187 = header.getOrDefault("X-Amz-Algorithm")
  valid_612187 = validateParameter(valid_612187, JString, required = false,
                                 default = nil)
  if valid_612187 != nil:
    section.add "X-Amz-Algorithm", valid_612187
  var valid_612188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612188 = validateParameter(valid_612188, JString, required = false,
                                 default = nil)
  if valid_612188 != nil:
    section.add "X-Amz-SignedHeaders", valid_612188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612190: Call_UpdateStage_612177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_612190.validator(path, query, header, formData, body)
  let scheme = call_612190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612190.url(scheme.get, call_612190.host, call_612190.base,
                         call_612190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612190, url, valid)

proc call*(call_612191: Call_UpdateStage_612177; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_612192 = newJObject()
  var body_612193 = newJObject()
  add(path_612192, "stageName", newJString(stageName))
  add(path_612192, "apiId", newJString(apiId))
  if body != nil:
    body_612193 = body
  result = call_612191.call(path_612192, nil, nil, nil, body_612193)

var updateStage* = Call_UpdateStage_612177(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_612178,
                                        base: "/", url: url_UpdateStage_612179,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_612162 = ref object of OpenApiRestCall_610658
proc url_DeleteStage_612164(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStage_612163(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_612165 = path.getOrDefault("stageName")
  valid_612165 = validateParameter(valid_612165, JString, required = true,
                                 default = nil)
  if valid_612165 != nil:
    section.add "stageName", valid_612165
  var valid_612166 = path.getOrDefault("apiId")
  valid_612166 = validateParameter(valid_612166, JString, required = true,
                                 default = nil)
  if valid_612166 != nil:
    section.add "apiId", valid_612166
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
  var valid_612167 = header.getOrDefault("X-Amz-Signature")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Signature", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Content-Sha256", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-Date")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-Date", valid_612169
  var valid_612170 = header.getOrDefault("X-Amz-Credential")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-Credential", valid_612170
  var valid_612171 = header.getOrDefault("X-Amz-Security-Token")
  valid_612171 = validateParameter(valid_612171, JString, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "X-Amz-Security-Token", valid_612171
  var valid_612172 = header.getOrDefault("X-Amz-Algorithm")
  valid_612172 = validateParameter(valid_612172, JString, required = false,
                                 default = nil)
  if valid_612172 != nil:
    section.add "X-Amz-Algorithm", valid_612172
  var valid_612173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612173 = validateParameter(valid_612173, JString, required = false,
                                 default = nil)
  if valid_612173 != nil:
    section.add "X-Amz-SignedHeaders", valid_612173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612174: Call_DeleteStage_612162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_612174.validator(path, query, header, formData, body)
  let scheme = call_612174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612174.url(scheme.get, call_612174.host, call_612174.base,
                         call_612174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612174, url, valid)

proc call*(call_612175: Call_DeleteStage_612162; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_612176 = newJObject()
  add(path_612176, "stageName", newJString(stageName))
  add(path_612176, "apiId", newJString(apiId))
  result = call_612175.call(path_612176, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_612162(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_612163,
                                        base: "/", url: url_DeleteStage_612164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_612194 = ref object of OpenApiRestCall_610658
proc url_GetModelTemplate_612196(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModelTemplate_612195(path: JsonNode; query: JsonNode;
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
  var valid_612197 = path.getOrDefault("apiId")
  valid_612197 = validateParameter(valid_612197, JString, required = true,
                                 default = nil)
  if valid_612197 != nil:
    section.add "apiId", valid_612197
  var valid_612198 = path.getOrDefault("modelId")
  valid_612198 = validateParameter(valid_612198, JString, required = true,
                                 default = nil)
  if valid_612198 != nil:
    section.add "modelId", valid_612198
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
  var valid_612199 = header.getOrDefault("X-Amz-Signature")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Signature", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Content-Sha256", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Date")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Date", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-Credential")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-Credential", valid_612202
  var valid_612203 = header.getOrDefault("X-Amz-Security-Token")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-Security-Token", valid_612203
  var valid_612204 = header.getOrDefault("X-Amz-Algorithm")
  valid_612204 = validateParameter(valid_612204, JString, required = false,
                                 default = nil)
  if valid_612204 != nil:
    section.add "X-Amz-Algorithm", valid_612204
  var valid_612205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "X-Amz-SignedHeaders", valid_612205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612206: Call_GetModelTemplate_612194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_612206.validator(path, query, header, formData, body)
  let scheme = call_612206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612206.url(scheme.get, call_612206.host, call_612206.base,
                         call_612206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612206, url, valid)

proc call*(call_612207: Call_GetModelTemplate_612194; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_612208 = newJObject()
  add(path_612208, "apiId", newJString(apiId))
  add(path_612208, "modelId", newJString(modelId))
  result = call_612207.call(path_612208, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_612194(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_612195, base: "/",
    url: url_GetModelTemplate_612196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612223 = ref object of OpenApiRestCall_610658
proc url_TagResource_612225(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_612224(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new Tag resource to represent a tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_612226 = path.getOrDefault("resource-arn")
  valid_612226 = validateParameter(valid_612226, JString, required = true,
                                 default = nil)
  if valid_612226 != nil:
    section.add "resource-arn", valid_612226
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
  var valid_612227 = header.getOrDefault("X-Amz-Signature")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Signature", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-Content-Sha256", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Date")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Date", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Credential")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Credential", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Security-Token")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Security-Token", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-Algorithm")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-Algorithm", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-SignedHeaders", valid_612233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612235: Call_TagResource_612223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Tag resource to represent a tag.
  ## 
  let valid = call_612235.validator(path, query, header, formData, body)
  let scheme = call_612235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612235.url(scheme.get, call_612235.host, call_612235.base,
                         call_612235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612235, url, valid)

proc call*(call_612236: Call_TagResource_612223; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a new Tag resource to represent a tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   body: JObject (required)
  var path_612237 = newJObject()
  var body_612238 = newJObject()
  add(path_612237, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_612238 = body
  result = call_612236.call(path_612237, nil, nil, nil, body_612238)

var tagResource* = Call_TagResource_612223(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_612224,
                                        base: "/", url: url_TagResource_612225,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_612209 = ref object of OpenApiRestCall_610658
proc url_GetTags_612211(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTags_612210(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of Tag resources.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_612212 = path.getOrDefault("resource-arn")
  valid_612212 = validateParameter(valid_612212, JString, required = true,
                                 default = nil)
  if valid_612212 != nil:
    section.add "resource-arn", valid_612212
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
  var valid_612213 = header.getOrDefault("X-Amz-Signature")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Signature", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Content-Sha256", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Date")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Date", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Credential")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Credential", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Security-Token")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Security-Token", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-Algorithm")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Algorithm", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-SignedHeaders", valid_612219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612220: Call_GetTags_612209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Tag resources.
  ## 
  let valid = call_612220.validator(path, query, header, formData, body)
  let scheme = call_612220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612220.url(scheme.get, call_612220.host, call_612220.base,
                         call_612220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612220, url, valid)

proc call*(call_612221: Call_GetTags_612209; resourceArn: string): Recallable =
  ## getTags
  ## Gets a collection of Tag resources.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  var path_612222 = newJObject()
  add(path_612222, "resource-arn", newJString(resourceArn))
  result = call_612221.call(path_612222, nil, nil, nil, nil)

var getTags* = Call_GetTags_612209(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_612210, base: "/",
                                url: url_GetTags_612211,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612239 = ref object of OpenApiRestCall_610658
proc url_UntagResource_612241(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_612240(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_612242 = path.getOrDefault("resource-arn")
  valid_612242 = validateParameter(valid_612242, JString, required = true,
                                 default = nil)
  if valid_612242 != nil:
    section.add "resource-arn", valid_612242
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_612243 = query.getOrDefault("tagKeys")
  valid_612243 = validateParameter(valid_612243, JArray, required = true, default = nil)
  if valid_612243 != nil:
    section.add "tagKeys", valid_612243
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
  var valid_612244 = header.getOrDefault("X-Amz-Signature")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Signature", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Content-Sha256", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Date")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Date", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Credential")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Credential", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-Security-Token")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-Security-Token", valid_612248
  var valid_612249 = header.getOrDefault("X-Amz-Algorithm")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "X-Amz-Algorithm", valid_612249
  var valid_612250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-SignedHeaders", valid_612250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612251: Call_UntagResource_612239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Tag.
  ## 
  let valid = call_612251.validator(path, query, header, formData, body)
  let scheme = call_612251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612251.url(scheme.get, call_612251.host, call_612251.base,
                         call_612251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612251, url, valid)

proc call*(call_612252: Call_UntagResource_612239; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a Tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  var path_612253 = newJObject()
  var query_612254 = newJObject()
  add(path_612253, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_612254.add "tagKeys", tagKeys
  result = call_612252.call(path_612253, query_612254, nil, nil, nil)

var untagResource* = Call_UntagResource_612239(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_612240,
    base: "/", url: url_UntagResource_612241, schemes: {Scheme.Https, Scheme.Http})
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
