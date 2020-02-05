
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
  Call_ImportApi_613253 = ref object of OpenApiRestCall_612658
proc url_ImportApi_613255(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApi_613254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613256 = query.getOrDefault("failOnWarnings")
  valid_613256 = validateParameter(valid_613256, JBool, required = false, default = nil)
  if valid_613256 != nil:
    section.add "failOnWarnings", valid_613256
  var valid_613257 = query.getOrDefault("basepath")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "basepath", valid_613257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613258 = header.getOrDefault("X-Amz-Signature")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Signature", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Content-Sha256", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Date")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Date", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Credential")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Credential", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Security-Token")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Security-Token", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Algorithm")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Algorithm", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-SignedHeaders", valid_613264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613266: Call_ImportApi_613253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an API.
  ## 
  let valid = call_613266.validator(path, query, header, formData, body)
  let scheme = call_613266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613266.url(scheme.get, call_613266.host, call_613266.base,
                         call_613266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613266, url, valid)

proc call*(call_613267: Call_ImportApi_613253; body: JsonNode;
          failOnWarnings: bool = false; basepath: string = ""): Recallable =
  ## importApi
  ## Imports an API.
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   body: JObject (required)
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  var query_613268 = newJObject()
  var body_613269 = newJObject()
  add(query_613268, "failOnWarnings", newJBool(failOnWarnings))
  if body != nil:
    body_613269 = body
  add(query_613268, "basepath", newJString(basepath))
  result = call_613267.call(nil, query_613268, nil, nil, body_613269)

var importApi* = Call_ImportApi_613253(name: "importApi", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_ImportApi_613254,
                                    base: "/", url: url_ImportApi_613255,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApi_613270 = ref object of OpenApiRestCall_612658
proc url_CreateApi_613272(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApi_613271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613273 = header.getOrDefault("X-Amz-Signature")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Signature", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Content-Sha256", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Date")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Date", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Credential")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Credential", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Security-Token")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Security-Token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Algorithm")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Algorithm", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-SignedHeaders", valid_613279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613281: Call_CreateApi_613270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_613281.validator(path, query, header, formData, body)
  let scheme = call_613281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613281.url(scheme.get, call_613281.host, call_613281.base,
                         call_613281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613281, url, valid)

proc call*(call_613282: Call_CreateApi_613270; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_613283 = newJObject()
  if body != nil:
    body_613283 = body
  result = call_613282.call(nil, nil, nil, nil, body_613283)

var createApi* = Call_CreateApi_613270(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_613271,
                                    base: "/", url: url_CreateApi_613272,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_612996 = ref object of OpenApiRestCall_612658
proc url_GetApis_612998(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApis_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613110 = query.getOrDefault("nextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "nextToken", valid_613110
  var valid_613111 = query.getOrDefault("maxResults")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "maxResults", valid_613111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613112 = header.getOrDefault("X-Amz-Signature")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Signature", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Content-Sha256", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Date")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Date", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Credential")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Credential", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Security-Token")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Security-Token", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Algorithm")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Algorithm", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-SignedHeaders", valid_613118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_GetApis_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613212: Call_GetApis_612996; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_613213 = newJObject()
  add(query_613213, "nextToken", newJString(nextToken))
  add(query_613213, "maxResults", newJString(maxResults))
  result = call_613212.call(nil, query_613213, nil, nil, nil)

var getApis* = Call_GetApis_612996(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_612997,
                                base: "/", url: url_GetApis_612998,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_613315 = ref object of OpenApiRestCall_612658
proc url_CreateApiMapping_613317(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiMapping_613316(path: JsonNode; query: JsonNode;
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
  var valid_613318 = path.getOrDefault("domainName")
  valid_613318 = validateParameter(valid_613318, JString, required = true,
                                 default = nil)
  if valid_613318 != nil:
    section.add "domainName", valid_613318
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

proc call*(call_613327: Call_CreateApiMapping_613315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_613327.validator(path, query, header, formData, body)
  let scheme = call_613327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613327.url(scheme.get, call_613327.host, call_613327.base,
                         call_613327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613327, url, valid)

proc call*(call_613328: Call_CreateApiMapping_613315; body: JsonNode;
          domainName: string): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_613329 = newJObject()
  var body_613330 = newJObject()
  if body != nil:
    body_613330 = body
  add(path_613329, "domainName", newJString(domainName))
  result = call_613328.call(path_613329, nil, nil, nil, body_613330)

var createApiMapping* = Call_CreateApiMapping_613315(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_613316, base: "/",
    url: url_CreateApiMapping_613317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_613284 = ref object of OpenApiRestCall_612658
proc url_GetApiMappings_613286(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMappings_613285(path: JsonNode; query: JsonNode;
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
  var valid_613301 = path.getOrDefault("domainName")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = nil)
  if valid_613301 != nil:
    section.add "domainName", valid_613301
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613302 = query.getOrDefault("nextToken")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "nextToken", valid_613302
  var valid_613303 = query.getOrDefault("maxResults")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "maxResults", valid_613303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613304 = header.getOrDefault("X-Amz-Signature")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Signature", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Content-Sha256", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Date")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Date", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Credential")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Credential", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Security-Token")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Security-Token", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Algorithm")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Algorithm", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-SignedHeaders", valid_613310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613311: Call_GetApiMappings_613284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets API mappings.
  ## 
  let valid = call_613311.validator(path, query, header, formData, body)
  let scheme = call_613311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613311.url(scheme.get, call_613311.host, call_613311.base,
                         call_613311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613311, url, valid)

proc call*(call_613312: Call_GetApiMappings_613284; domainName: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getApiMappings
  ## Gets API mappings.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_613313 = newJObject()
  var query_613314 = newJObject()
  add(query_613314, "nextToken", newJString(nextToken))
  add(path_613313, "domainName", newJString(domainName))
  add(query_613314, "maxResults", newJString(maxResults))
  result = call_613312.call(path_613313, query_613314, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_613284(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_613285, base: "/", url: url_GetApiMappings_613286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_613348 = ref object of OpenApiRestCall_612658
proc url_CreateAuthorizer_613350(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAuthorizer_613349(path: JsonNode; query: JsonNode;
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
  var valid_613351 = path.getOrDefault("apiId")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "apiId", valid_613351
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
  var valid_613352 = header.getOrDefault("X-Amz-Signature")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Signature", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Content-Sha256", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Date")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Date", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Credential")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Credential", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Security-Token")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Security-Token", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Algorithm")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Algorithm", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-SignedHeaders", valid_613358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_CreateAuthorizer_613348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_CreateAuthorizer_613348; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_613362 = newJObject()
  var body_613363 = newJObject()
  add(path_613362, "apiId", newJString(apiId))
  if body != nil:
    body_613363 = body
  result = call_613361.call(path_613362, nil, nil, nil, body_613363)

var createAuthorizer* = Call_CreateAuthorizer_613348(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_613349,
    base: "/", url: url_CreateAuthorizer_613350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_613331 = ref object of OpenApiRestCall_612658
proc url_GetAuthorizers_613333(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizers_613332(path: JsonNode; query: JsonNode;
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
  var valid_613334 = path.getOrDefault("apiId")
  valid_613334 = validateParameter(valid_613334, JString, required = true,
                                 default = nil)
  if valid_613334 != nil:
    section.add "apiId", valid_613334
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613335 = query.getOrDefault("nextToken")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "nextToken", valid_613335
  var valid_613336 = query.getOrDefault("maxResults")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "maxResults", valid_613336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613337 = header.getOrDefault("X-Amz-Signature")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Signature", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Content-Sha256", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Date")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Date", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Credential")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Credential", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Security-Token")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Security-Token", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Algorithm")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Algorithm", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-SignedHeaders", valid_613343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613344: Call_GetAuthorizers_613331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_613344.validator(path, query, header, formData, body)
  let scheme = call_613344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613344.url(scheme.get, call_613344.host, call_613344.base,
                         call_613344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613344, url, valid)

proc call*(call_613345: Call_GetAuthorizers_613331; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_613346 = newJObject()
  var query_613347 = newJObject()
  add(query_613347, "nextToken", newJString(nextToken))
  add(path_613346, "apiId", newJString(apiId))
  add(query_613347, "maxResults", newJString(maxResults))
  result = call_613345.call(path_613346, query_613347, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_613331(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_613332,
    base: "/", url: url_GetAuthorizers_613333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_613381 = ref object of OpenApiRestCall_612658
proc url_CreateDeployment_613383(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_613382(path: JsonNode; query: JsonNode;
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
  var valid_613384 = path.getOrDefault("apiId")
  valid_613384 = validateParameter(valid_613384, JString, required = true,
                                 default = nil)
  if valid_613384 != nil:
    section.add "apiId", valid_613384
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
  var valid_613385 = header.getOrDefault("X-Amz-Signature")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Signature", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Content-Sha256", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Date")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Date", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Credential")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Credential", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Security-Token")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Security-Token", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Algorithm")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Algorithm", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-SignedHeaders", valid_613391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613393: Call_CreateDeployment_613381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_613393.validator(path, query, header, formData, body)
  let scheme = call_613393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613393.url(scheme.get, call_613393.host, call_613393.base,
                         call_613393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613393, url, valid)

proc call*(call_613394: Call_CreateDeployment_613381; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_613395 = newJObject()
  var body_613396 = newJObject()
  add(path_613395, "apiId", newJString(apiId))
  if body != nil:
    body_613396 = body
  result = call_613394.call(path_613395, nil, nil, nil, body_613396)

var createDeployment* = Call_CreateDeployment_613381(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_613382,
    base: "/", url: url_CreateDeployment_613383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_613364 = ref object of OpenApiRestCall_612658
proc url_GetDeployments_613366(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployments_613365(path: JsonNode; query: JsonNode;
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
  var valid_613367 = path.getOrDefault("apiId")
  valid_613367 = validateParameter(valid_613367, JString, required = true,
                                 default = nil)
  if valid_613367 != nil:
    section.add "apiId", valid_613367
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613368 = query.getOrDefault("nextToken")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "nextToken", valid_613368
  var valid_613369 = query.getOrDefault("maxResults")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "maxResults", valid_613369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613370 = header.getOrDefault("X-Amz-Signature")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Signature", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Content-Sha256", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Date")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Date", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Credential")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Credential", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Security-Token")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Security-Token", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Algorithm")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Algorithm", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-SignedHeaders", valid_613376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613377: Call_GetDeployments_613364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_613377.validator(path, query, header, formData, body)
  let scheme = call_613377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613377.url(scheme.get, call_613377.host, call_613377.base,
                         call_613377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613377, url, valid)

proc call*(call_613378: Call_GetDeployments_613364; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_613379 = newJObject()
  var query_613380 = newJObject()
  add(query_613380, "nextToken", newJString(nextToken))
  add(path_613379, "apiId", newJString(apiId))
  add(query_613380, "maxResults", newJString(maxResults))
  result = call_613378.call(path_613379, query_613380, nil, nil, nil)

var getDeployments* = Call_GetDeployments_613364(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_613365,
    base: "/", url: url_GetDeployments_613366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_613412 = ref object of OpenApiRestCall_612658
proc url_CreateDomainName_613414(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainName_613413(path: JsonNode; query: JsonNode;
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613423: Call_CreateDomainName_613412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_613423.validator(path, query, header, formData, body)
  let scheme = call_613423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613423.url(scheme.get, call_613423.host, call_613423.base,
                         call_613423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613423, url, valid)

proc call*(call_613424: Call_CreateDomainName_613412; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_613425 = newJObject()
  if body != nil:
    body_613425 = body
  result = call_613424.call(nil, nil, nil, nil, body_613425)

var createDomainName* = Call_CreateDomainName_613412(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_613413,
    base: "/", url: url_CreateDomainName_613414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_613397 = ref object of OpenApiRestCall_612658
proc url_GetDomainNames_613399(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainNames_613398(path: JsonNode; query: JsonNode;
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
  var valid_613400 = query.getOrDefault("nextToken")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "nextToken", valid_613400
  var valid_613401 = query.getOrDefault("maxResults")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "maxResults", valid_613401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613402 = header.getOrDefault("X-Amz-Signature")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Signature", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Content-Sha256", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Date")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Date", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Credential")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Credential", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Security-Token")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Security-Token", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Algorithm")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Algorithm", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-SignedHeaders", valid_613408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613409: Call_GetDomainNames_613397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_613409.validator(path, query, header, formData, body)
  let scheme = call_613409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613409.url(scheme.get, call_613409.host, call_613409.base,
                         call_613409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613409, url, valid)

proc call*(call_613410: Call_GetDomainNames_613397; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_613411 = newJObject()
  add(query_613411, "nextToken", newJString(nextToken))
  add(query_613411, "maxResults", newJString(maxResults))
  result = call_613410.call(nil, query_613411, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_613397(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_613398, base: "/",
    url: url_GetDomainNames_613399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_613443 = ref object of OpenApiRestCall_612658
proc url_CreateIntegration_613445(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegration_613444(path: JsonNode; query: JsonNode;
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
  var valid_613446 = path.getOrDefault("apiId")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "apiId", valid_613446
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
  var valid_613447 = header.getOrDefault("X-Amz-Signature")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Signature", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Content-Sha256", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Date")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Date", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Credential")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Credential", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Security-Token")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Security-Token", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Algorithm")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Algorithm", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-SignedHeaders", valid_613453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613455: Call_CreateIntegration_613443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_613455.validator(path, query, header, formData, body)
  let scheme = call_613455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613455.url(scheme.get, call_613455.host, call_613455.base,
                         call_613455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613455, url, valid)

proc call*(call_613456: Call_CreateIntegration_613443; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_613457 = newJObject()
  var body_613458 = newJObject()
  add(path_613457, "apiId", newJString(apiId))
  if body != nil:
    body_613458 = body
  result = call_613456.call(path_613457, nil, nil, nil, body_613458)

var createIntegration* = Call_CreateIntegration_613443(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_613444,
    base: "/", url: url_CreateIntegration_613445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_613426 = ref object of OpenApiRestCall_612658
proc url_GetIntegrations_613428(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrations_613427(path: JsonNode; query: JsonNode;
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
  var valid_613429 = path.getOrDefault("apiId")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = nil)
  if valid_613429 != nil:
    section.add "apiId", valid_613429
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613430 = query.getOrDefault("nextToken")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "nextToken", valid_613430
  var valid_613431 = query.getOrDefault("maxResults")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "maxResults", valid_613431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613432 = header.getOrDefault("X-Amz-Signature")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Signature", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Content-Sha256", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Date")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Date", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Credential")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Credential", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Security-Token")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Security-Token", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Algorithm")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Algorithm", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-SignedHeaders", valid_613438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613439: Call_GetIntegrations_613426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_613439.validator(path, query, header, formData, body)
  let scheme = call_613439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613439.url(scheme.get, call_613439.host, call_613439.base,
                         call_613439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613439, url, valid)

proc call*(call_613440: Call_GetIntegrations_613426; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_613441 = newJObject()
  var query_613442 = newJObject()
  add(query_613442, "nextToken", newJString(nextToken))
  add(path_613441, "apiId", newJString(apiId))
  add(query_613442, "maxResults", newJString(maxResults))
  result = call_613440.call(path_613441, query_613442, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_613426(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_613427,
    base: "/", url: url_GetIntegrations_613428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_613477 = ref object of OpenApiRestCall_612658
proc url_CreateIntegrationResponse_613479(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegrationResponse_613478(path: JsonNode; query: JsonNode;
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
  var valid_613480 = path.getOrDefault("apiId")
  valid_613480 = validateParameter(valid_613480, JString, required = true,
                                 default = nil)
  if valid_613480 != nil:
    section.add "apiId", valid_613480
  var valid_613481 = path.getOrDefault("integrationId")
  valid_613481 = validateParameter(valid_613481, JString, required = true,
                                 default = nil)
  if valid_613481 != nil:
    section.add "integrationId", valid_613481
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
  var valid_613482 = header.getOrDefault("X-Amz-Signature")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Signature", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Content-Sha256", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Date")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Date", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Credential")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Credential", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Security-Token")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Security-Token", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Algorithm")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Algorithm", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-SignedHeaders", valid_613488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613490: Call_CreateIntegrationResponse_613477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_613490.validator(path, query, header, formData, body)
  let scheme = call_613490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613490.url(scheme.get, call_613490.host, call_613490.base,
                         call_613490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613490, url, valid)

proc call*(call_613491: Call_CreateIntegrationResponse_613477; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_613492 = newJObject()
  var body_613493 = newJObject()
  add(path_613492, "apiId", newJString(apiId))
  add(path_613492, "integrationId", newJString(integrationId))
  if body != nil:
    body_613493 = body
  result = call_613491.call(path_613492, nil, nil, nil, body_613493)

var createIntegrationResponse* = Call_CreateIntegrationResponse_613477(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_613478, base: "/",
    url: url_CreateIntegrationResponse_613479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_613459 = ref object of OpenApiRestCall_612658
proc url_GetIntegrationResponses_613461(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponses_613460(path: JsonNode; query: JsonNode;
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
  var valid_613462 = path.getOrDefault("apiId")
  valid_613462 = validateParameter(valid_613462, JString, required = true,
                                 default = nil)
  if valid_613462 != nil:
    section.add "apiId", valid_613462
  var valid_613463 = path.getOrDefault("integrationId")
  valid_613463 = validateParameter(valid_613463, JString, required = true,
                                 default = nil)
  if valid_613463 != nil:
    section.add "integrationId", valid_613463
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613464 = query.getOrDefault("nextToken")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "nextToken", valid_613464
  var valid_613465 = query.getOrDefault("maxResults")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "maxResults", valid_613465
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613466 = header.getOrDefault("X-Amz-Signature")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Signature", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Content-Sha256", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Date")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Date", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Credential")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Credential", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Security-Token")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Security-Token", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Algorithm")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Algorithm", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-SignedHeaders", valid_613472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613473: Call_GetIntegrationResponses_613459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_613473.validator(path, query, header, formData, body)
  let scheme = call_613473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613473.url(scheme.get, call_613473.host, call_613473.base,
                         call_613473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613473, url, valid)

proc call*(call_613474: Call_GetIntegrationResponses_613459; apiId: string;
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
  var path_613475 = newJObject()
  var query_613476 = newJObject()
  add(query_613476, "nextToken", newJString(nextToken))
  add(path_613475, "apiId", newJString(apiId))
  add(path_613475, "integrationId", newJString(integrationId))
  add(query_613476, "maxResults", newJString(maxResults))
  result = call_613474.call(path_613475, query_613476, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_613459(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_613460, base: "/",
    url: url_GetIntegrationResponses_613461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_613511 = ref object of OpenApiRestCall_612658
proc url_CreateModel_613513(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateModel_613512(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613514 = path.getOrDefault("apiId")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = nil)
  if valid_613514 != nil:
    section.add "apiId", valid_613514
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
  var valid_613515 = header.getOrDefault("X-Amz-Signature")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Signature", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Content-Sha256", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Date")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Date", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Credential")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Credential", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Security-Token")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Security-Token", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Algorithm")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Algorithm", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-SignedHeaders", valid_613521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613523: Call_CreateModel_613511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_613523.validator(path, query, header, formData, body)
  let scheme = call_613523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613523.url(scheme.get, call_613523.host, call_613523.base,
                         call_613523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613523, url, valid)

proc call*(call_613524: Call_CreateModel_613511; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_613525 = newJObject()
  var body_613526 = newJObject()
  add(path_613525, "apiId", newJString(apiId))
  if body != nil:
    body_613526 = body
  result = call_613524.call(path_613525, nil, nil, nil, body_613526)

var createModel* = Call_CreateModel_613511(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_613512,
                                        base: "/", url: url_CreateModel_613513,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_613494 = ref object of OpenApiRestCall_612658
proc url_GetModels_613496(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModels_613495(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613497 = path.getOrDefault("apiId")
  valid_613497 = validateParameter(valid_613497, JString, required = true,
                                 default = nil)
  if valid_613497 != nil:
    section.add "apiId", valid_613497
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613498 = query.getOrDefault("nextToken")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "nextToken", valid_613498
  var valid_613499 = query.getOrDefault("maxResults")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "maxResults", valid_613499
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613500 = header.getOrDefault("X-Amz-Signature")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Signature", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Content-Sha256", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Date")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Date", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Credential")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Credential", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Security-Token")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Security-Token", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Algorithm")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Algorithm", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-SignedHeaders", valid_613506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613507: Call_GetModels_613494; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_613507.validator(path, query, header, formData, body)
  let scheme = call_613507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613507.url(scheme.get, call_613507.host, call_613507.base,
                         call_613507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613507, url, valid)

proc call*(call_613508: Call_GetModels_613494; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_613509 = newJObject()
  var query_613510 = newJObject()
  add(query_613510, "nextToken", newJString(nextToken))
  add(path_613509, "apiId", newJString(apiId))
  add(query_613510, "maxResults", newJString(maxResults))
  result = call_613508.call(path_613509, query_613510, nil, nil, nil)

var getModels* = Call_GetModels_613494(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_613495,
                                    base: "/", url: url_GetModels_613496,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_613544 = ref object of OpenApiRestCall_612658
proc url_CreateRoute_613546(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoute_613545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613547 = path.getOrDefault("apiId")
  valid_613547 = validateParameter(valid_613547, JString, required = true,
                                 default = nil)
  if valid_613547 != nil:
    section.add "apiId", valid_613547
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613556: Call_CreateRoute_613544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_613556.validator(path, query, header, formData, body)
  let scheme = call_613556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613556.url(scheme.get, call_613556.host, call_613556.base,
                         call_613556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613556, url, valid)

proc call*(call_613557: Call_CreateRoute_613544; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_613558 = newJObject()
  var body_613559 = newJObject()
  add(path_613558, "apiId", newJString(apiId))
  if body != nil:
    body_613559 = body
  result = call_613557.call(path_613558, nil, nil, nil, body_613559)

var createRoute* = Call_CreateRoute_613544(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_613545,
                                        base: "/", url: url_CreateRoute_613546,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_613527 = ref object of OpenApiRestCall_612658
proc url_GetRoutes_613529(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoutes_613528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613530 = path.getOrDefault("apiId")
  valid_613530 = validateParameter(valid_613530, JString, required = true,
                                 default = nil)
  if valid_613530 != nil:
    section.add "apiId", valid_613530
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613531 = query.getOrDefault("nextToken")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "nextToken", valid_613531
  var valid_613532 = query.getOrDefault("maxResults")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "maxResults", valid_613532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613533 = header.getOrDefault("X-Amz-Signature")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Signature", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Content-Sha256", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Date")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Date", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Credential")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Credential", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Security-Token")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Security-Token", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Algorithm")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Algorithm", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-SignedHeaders", valid_613539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613540: Call_GetRoutes_613527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_613540.validator(path, query, header, formData, body)
  let scheme = call_613540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613540.url(scheme.get, call_613540.host, call_613540.base,
                         call_613540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613540, url, valid)

proc call*(call_613541: Call_GetRoutes_613527; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_613542 = newJObject()
  var query_613543 = newJObject()
  add(query_613543, "nextToken", newJString(nextToken))
  add(path_613542, "apiId", newJString(apiId))
  add(query_613543, "maxResults", newJString(maxResults))
  result = call_613541.call(path_613542, query_613543, nil, nil, nil)

var getRoutes* = Call_GetRoutes_613527(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_613528,
                                    base: "/", url: url_GetRoutes_613529,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_613578 = ref object of OpenApiRestCall_612658
proc url_CreateRouteResponse_613580(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRouteResponse_613579(path: JsonNode; query: JsonNode;
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
  var valid_613581 = path.getOrDefault("apiId")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = nil)
  if valid_613581 != nil:
    section.add "apiId", valid_613581
  var valid_613582 = path.getOrDefault("routeId")
  valid_613582 = validateParameter(valid_613582, JString, required = true,
                                 default = nil)
  if valid_613582 != nil:
    section.add "routeId", valid_613582
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
  var valid_613583 = header.getOrDefault("X-Amz-Signature")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Signature", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Content-Sha256", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Date")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Date", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Credential")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Credential", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Security-Token")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Security-Token", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Algorithm")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Algorithm", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-SignedHeaders", valid_613589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613591: Call_CreateRouteResponse_613578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_613591.validator(path, query, header, formData, body)
  let scheme = call_613591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613591.url(scheme.get, call_613591.host, call_613591.base,
                         call_613591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613591, url, valid)

proc call*(call_613592: Call_CreateRouteResponse_613578; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_613593 = newJObject()
  var body_613594 = newJObject()
  add(path_613593, "apiId", newJString(apiId))
  if body != nil:
    body_613594 = body
  add(path_613593, "routeId", newJString(routeId))
  result = call_613592.call(path_613593, nil, nil, nil, body_613594)

var createRouteResponse* = Call_CreateRouteResponse_613578(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_613579, base: "/",
    url: url_CreateRouteResponse_613580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_613560 = ref object of OpenApiRestCall_612658
proc url_GetRouteResponses_613562(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponses_613561(path: JsonNode; query: JsonNode;
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
  var valid_613563 = path.getOrDefault("apiId")
  valid_613563 = validateParameter(valid_613563, JString, required = true,
                                 default = nil)
  if valid_613563 != nil:
    section.add "apiId", valid_613563
  var valid_613564 = path.getOrDefault("routeId")
  valid_613564 = validateParameter(valid_613564, JString, required = true,
                                 default = nil)
  if valid_613564 != nil:
    section.add "routeId", valid_613564
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613565 = query.getOrDefault("nextToken")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "nextToken", valid_613565
  var valid_613566 = query.getOrDefault("maxResults")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "maxResults", valid_613566
  result.add "query", section
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

proc call*(call_613574: Call_GetRouteResponses_613560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_613574.validator(path, query, header, formData, body)
  let scheme = call_613574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613574.url(scheme.get, call_613574.host, call_613574.base,
                         call_613574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613574, url, valid)

proc call*(call_613575: Call_GetRouteResponses_613560; apiId: string;
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
  var path_613576 = newJObject()
  var query_613577 = newJObject()
  add(query_613577, "nextToken", newJString(nextToken))
  add(path_613576, "apiId", newJString(apiId))
  add(path_613576, "routeId", newJString(routeId))
  add(query_613577, "maxResults", newJString(maxResults))
  result = call_613575.call(path_613576, query_613577, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_613560(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_613561, base: "/",
    url: url_GetRouteResponses_613562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_613612 = ref object of OpenApiRestCall_612658
proc url_CreateStage_613614(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateStage_613613(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613615 = path.getOrDefault("apiId")
  valid_613615 = validateParameter(valid_613615, JString, required = true,
                                 default = nil)
  if valid_613615 != nil:
    section.add "apiId", valid_613615
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

proc call*(call_613624: Call_CreateStage_613612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_613624.validator(path, query, header, formData, body)
  let scheme = call_613624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613624.url(scheme.get, call_613624.host, call_613624.base,
                         call_613624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613624, url, valid)

proc call*(call_613625: Call_CreateStage_613612; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_613626 = newJObject()
  var body_613627 = newJObject()
  add(path_613626, "apiId", newJString(apiId))
  if body != nil:
    body_613627 = body
  result = call_613625.call(path_613626, nil, nil, nil, body_613627)

var createStage* = Call_CreateStage_613612(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_613613,
                                        base: "/", url: url_CreateStage_613614,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_613595 = ref object of OpenApiRestCall_612658
proc url_GetStages_613597(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStages_613596(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613598 = path.getOrDefault("apiId")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "apiId", valid_613598
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_613599 = query.getOrDefault("nextToken")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "nextToken", valid_613599
  var valid_613600 = query.getOrDefault("maxResults")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "maxResults", valid_613600
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613601 = header.getOrDefault("X-Amz-Signature")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Signature", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Content-Sha256", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Date")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Date", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Credential")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Credential", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Security-Token")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Security-Token", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Algorithm")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Algorithm", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-SignedHeaders", valid_613607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613608: Call_GetStages_613595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_613608.validator(path, query, header, formData, body)
  let scheme = call_613608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613608.url(scheme.get, call_613608.host, call_613608.base,
                         call_613608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613608, url, valid)

proc call*(call_613609: Call_GetStages_613595; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_613610 = newJObject()
  var query_613611 = newJObject()
  add(query_613611, "nextToken", newJString(nextToken))
  add(path_613610, "apiId", newJString(apiId))
  add(query_613611, "maxResults", newJString(maxResults))
  result = call_613609.call(path_613610, query_613611, nil, nil, nil)

var getStages* = Call_GetStages_613595(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_613596,
                                    base: "/", url: url_GetStages_613597,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReimportApi_613642 = ref object of OpenApiRestCall_612658
proc url_ReimportApi_613644(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReimportApi_613643(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613645 = path.getOrDefault("apiId")
  valid_613645 = validateParameter(valid_613645, JString, required = true,
                                 default = nil)
  if valid_613645 != nil:
    section.add "apiId", valid_613645
  result.add "path", section
  ## parameters in `query` object:
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  section = newJObject()
  var valid_613646 = query.getOrDefault("failOnWarnings")
  valid_613646 = validateParameter(valid_613646, JBool, required = false, default = nil)
  if valid_613646 != nil:
    section.add "failOnWarnings", valid_613646
  var valid_613647 = query.getOrDefault("basepath")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "basepath", valid_613647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613648 = header.getOrDefault("X-Amz-Signature")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Signature", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Content-Sha256", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Date")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Date", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Credential")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Credential", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Security-Token")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Security-Token", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Algorithm")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Algorithm", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-SignedHeaders", valid_613654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613656: Call_ReimportApi_613642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts an Api resource.
  ## 
  let valid = call_613656.validator(path, query, header, formData, body)
  let scheme = call_613656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613656.url(scheme.get, call_613656.host, call_613656.base,
                         call_613656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613656, url, valid)

proc call*(call_613657: Call_ReimportApi_613642; apiId: string; body: JsonNode;
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
  var path_613658 = newJObject()
  var query_613659 = newJObject()
  var body_613660 = newJObject()
  add(query_613659, "failOnWarnings", newJBool(failOnWarnings))
  add(path_613658, "apiId", newJString(apiId))
  if body != nil:
    body_613660 = body
  add(query_613659, "basepath", newJString(basepath))
  result = call_613657.call(path_613658, query_613659, nil, nil, body_613660)

var reimportApi* = Call_ReimportApi_613642(name: "reimportApi",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}",
                                        validator: validate_ReimportApi_613643,
                                        base: "/", url: url_ReimportApi_613644,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_613628 = ref object of OpenApiRestCall_612658
proc url_GetApi_613630(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApi_613629(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613631 = path.getOrDefault("apiId")
  valid_613631 = validateParameter(valid_613631, JString, required = true,
                                 default = nil)
  if valid_613631 != nil:
    section.add "apiId", valid_613631
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
  var valid_613632 = header.getOrDefault("X-Amz-Signature")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Signature", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Content-Sha256", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Date")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Date", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Credential")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Credential", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Security-Token")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Security-Token", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Algorithm")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Algorithm", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-SignedHeaders", valid_613638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613639: Call_GetApi_613628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_613639.validator(path, query, header, formData, body)
  let scheme = call_613639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613639.url(scheme.get, call_613639.host, call_613639.base,
                         call_613639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613639, url, valid)

proc call*(call_613640: Call_GetApi_613628; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_613641 = newJObject()
  add(path_613641, "apiId", newJString(apiId))
  result = call_613640.call(path_613641, nil, nil, nil, nil)

var getApi* = Call_GetApi_613628(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_613629, base: "/",
                              url: url_GetApi_613630,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_613675 = ref object of OpenApiRestCall_612658
proc url_UpdateApi_613677(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApi_613676(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613678 = path.getOrDefault("apiId")
  valid_613678 = validateParameter(valid_613678, JString, required = true,
                                 default = nil)
  if valid_613678 != nil:
    section.add "apiId", valid_613678
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
  var valid_613679 = header.getOrDefault("X-Amz-Signature")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Signature", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Content-Sha256", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Date")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Date", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Credential")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Credential", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Security-Token")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Security-Token", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Algorithm")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Algorithm", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-SignedHeaders", valid_613685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613687: Call_UpdateApi_613675; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_613687.validator(path, query, header, formData, body)
  let scheme = call_613687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613687.url(scheme.get, call_613687.host, call_613687.base,
                         call_613687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613687, url, valid)

proc call*(call_613688: Call_UpdateApi_613675; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_613689 = newJObject()
  var body_613690 = newJObject()
  add(path_613689, "apiId", newJString(apiId))
  if body != nil:
    body_613690 = body
  result = call_613688.call(path_613689, nil, nil, nil, body_613690)

var updateApi* = Call_UpdateApi_613675(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_613676,
                                    base: "/", url: url_UpdateApi_613677,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_613661 = ref object of OpenApiRestCall_612658
proc url_DeleteApi_613663(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApi_613662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613664 = path.getOrDefault("apiId")
  valid_613664 = validateParameter(valid_613664, JString, required = true,
                                 default = nil)
  if valid_613664 != nil:
    section.add "apiId", valid_613664
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
  var valid_613665 = header.getOrDefault("X-Amz-Signature")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Signature", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Content-Sha256", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Date")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Date", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Credential")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Credential", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Security-Token")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Security-Token", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Algorithm")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Algorithm", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-SignedHeaders", valid_613671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613672: Call_DeleteApi_613661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_613672.validator(path, query, header, formData, body)
  let scheme = call_613672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613672.url(scheme.get, call_613672.host, call_613672.base,
                         call_613672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613672, url, valid)

proc call*(call_613673: Call_DeleteApi_613661; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_613674 = newJObject()
  add(path_613674, "apiId", newJString(apiId))
  result = call_613673.call(path_613674, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_613661(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_613662,
                                    base: "/", url: url_DeleteApi_613663,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_613691 = ref object of OpenApiRestCall_612658
proc url_GetApiMapping_613693(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMapping_613692(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613694 = path.getOrDefault("apiMappingId")
  valid_613694 = validateParameter(valid_613694, JString, required = true,
                                 default = nil)
  if valid_613694 != nil:
    section.add "apiMappingId", valid_613694
  var valid_613695 = path.getOrDefault("domainName")
  valid_613695 = validateParameter(valid_613695, JString, required = true,
                                 default = nil)
  if valid_613695 != nil:
    section.add "domainName", valid_613695
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
  var valid_613696 = header.getOrDefault("X-Amz-Signature")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Signature", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Content-Sha256", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Date")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Date", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Credential")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Credential", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Security-Token")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Security-Token", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Algorithm")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Algorithm", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-SignedHeaders", valid_613702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613703: Call_GetApiMapping_613691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an API mapping.
  ## 
  let valid = call_613703.validator(path, query, header, formData, body)
  let scheme = call_613703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613703.url(scheme.get, call_613703.host, call_613703.base,
                         call_613703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613703, url, valid)

proc call*(call_613704: Call_GetApiMapping_613691; apiMappingId: string;
          domainName: string): Recallable =
  ## getApiMapping
  ## Gets an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_613705 = newJObject()
  add(path_613705, "apiMappingId", newJString(apiMappingId))
  add(path_613705, "domainName", newJString(domainName))
  result = call_613704.call(path_613705, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_613691(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_613692, base: "/", url: url_GetApiMapping_613693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_613721 = ref object of OpenApiRestCall_612658
proc url_UpdateApiMapping_613723(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiMapping_613722(path: JsonNode; query: JsonNode;
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
  var valid_613724 = path.getOrDefault("apiMappingId")
  valid_613724 = validateParameter(valid_613724, JString, required = true,
                                 default = nil)
  if valid_613724 != nil:
    section.add "apiMappingId", valid_613724
  var valid_613725 = path.getOrDefault("domainName")
  valid_613725 = validateParameter(valid_613725, JString, required = true,
                                 default = nil)
  if valid_613725 != nil:
    section.add "domainName", valid_613725
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
  var valid_613726 = header.getOrDefault("X-Amz-Signature")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Signature", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Content-Sha256", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Date")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Date", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Credential")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Credential", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Security-Token")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Security-Token", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Algorithm")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Algorithm", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-SignedHeaders", valid_613732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613734: Call_UpdateApiMapping_613721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_613734.validator(path, query, header, formData, body)
  let scheme = call_613734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613734.url(scheme.get, call_613734.host, call_613734.base,
                         call_613734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613734, url, valid)

proc call*(call_613735: Call_UpdateApiMapping_613721; apiMappingId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_613736 = newJObject()
  var body_613737 = newJObject()
  add(path_613736, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_613737 = body
  add(path_613736, "domainName", newJString(domainName))
  result = call_613735.call(path_613736, nil, nil, nil, body_613737)

var updateApiMapping* = Call_UpdateApiMapping_613721(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_613722, base: "/",
    url: url_UpdateApiMapping_613723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_613706 = ref object of OpenApiRestCall_612658
proc url_DeleteApiMapping_613708(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiMapping_613707(path: JsonNode; query: JsonNode;
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
  var valid_613709 = path.getOrDefault("apiMappingId")
  valid_613709 = validateParameter(valid_613709, JString, required = true,
                                 default = nil)
  if valid_613709 != nil:
    section.add "apiMappingId", valid_613709
  var valid_613710 = path.getOrDefault("domainName")
  valid_613710 = validateParameter(valid_613710, JString, required = true,
                                 default = nil)
  if valid_613710 != nil:
    section.add "domainName", valid_613710
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
  var valid_613711 = header.getOrDefault("X-Amz-Signature")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Signature", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Content-Sha256", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Date")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Date", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Credential")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Credential", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Security-Token")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Security-Token", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Algorithm")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Algorithm", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-SignedHeaders", valid_613717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613718: Call_DeleteApiMapping_613706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_613718.validator(path, query, header, formData, body)
  let scheme = call_613718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613718.url(scheme.get, call_613718.host, call_613718.base,
                         call_613718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613718, url, valid)

proc call*(call_613719: Call_DeleteApiMapping_613706; apiMappingId: string;
          domainName: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_613720 = newJObject()
  add(path_613720, "apiMappingId", newJString(apiMappingId))
  add(path_613720, "domainName", newJString(domainName))
  result = call_613719.call(path_613720, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_613706(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_613707, base: "/",
    url: url_DeleteApiMapping_613708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_613738 = ref object of OpenApiRestCall_612658
proc url_GetAuthorizer_613740(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizer_613739(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613741 = path.getOrDefault("apiId")
  valid_613741 = validateParameter(valid_613741, JString, required = true,
                                 default = nil)
  if valid_613741 != nil:
    section.add "apiId", valid_613741
  var valid_613742 = path.getOrDefault("authorizerId")
  valid_613742 = validateParameter(valid_613742, JString, required = true,
                                 default = nil)
  if valid_613742 != nil:
    section.add "authorizerId", valid_613742
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
  var valid_613743 = header.getOrDefault("X-Amz-Signature")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Signature", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Content-Sha256", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Date")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Date", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Credential")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Credential", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Security-Token")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Security-Token", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Algorithm")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Algorithm", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-SignedHeaders", valid_613749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613750: Call_GetAuthorizer_613738; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_613750.validator(path, query, header, formData, body)
  let scheme = call_613750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613750.url(scheme.get, call_613750.host, call_613750.base,
                         call_613750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613750, url, valid)

proc call*(call_613751: Call_GetAuthorizer_613738; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_613752 = newJObject()
  add(path_613752, "apiId", newJString(apiId))
  add(path_613752, "authorizerId", newJString(authorizerId))
  result = call_613751.call(path_613752, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_613738(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_613739, base: "/", url: url_GetAuthorizer_613740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_613768 = ref object of OpenApiRestCall_612658
proc url_UpdateAuthorizer_613770(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAuthorizer_613769(path: JsonNode; query: JsonNode;
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
  var valid_613771 = path.getOrDefault("apiId")
  valid_613771 = validateParameter(valid_613771, JString, required = true,
                                 default = nil)
  if valid_613771 != nil:
    section.add "apiId", valid_613771
  var valid_613772 = path.getOrDefault("authorizerId")
  valid_613772 = validateParameter(valid_613772, JString, required = true,
                                 default = nil)
  if valid_613772 != nil:
    section.add "authorizerId", valid_613772
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
  var valid_613773 = header.getOrDefault("X-Amz-Signature")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Signature", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Content-Sha256", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Date")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Date", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Credential")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Credential", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Security-Token")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Security-Token", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Algorithm")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Algorithm", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-SignedHeaders", valid_613779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613781: Call_UpdateAuthorizer_613768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_613781.validator(path, query, header, formData, body)
  let scheme = call_613781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613781.url(scheme.get, call_613781.host, call_613781.base,
                         call_613781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613781, url, valid)

proc call*(call_613782: Call_UpdateAuthorizer_613768; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_613783 = newJObject()
  var body_613784 = newJObject()
  add(path_613783, "apiId", newJString(apiId))
  add(path_613783, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_613784 = body
  result = call_613782.call(path_613783, nil, nil, nil, body_613784)

var updateAuthorizer* = Call_UpdateAuthorizer_613768(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_613769, base: "/",
    url: url_UpdateAuthorizer_613770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_613753 = ref object of OpenApiRestCall_612658
proc url_DeleteAuthorizer_613755(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAuthorizer_613754(path: JsonNode; query: JsonNode;
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
  var valid_613756 = path.getOrDefault("apiId")
  valid_613756 = validateParameter(valid_613756, JString, required = true,
                                 default = nil)
  if valid_613756 != nil:
    section.add "apiId", valid_613756
  var valid_613757 = path.getOrDefault("authorizerId")
  valid_613757 = validateParameter(valid_613757, JString, required = true,
                                 default = nil)
  if valid_613757 != nil:
    section.add "authorizerId", valid_613757
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
  var valid_613758 = header.getOrDefault("X-Amz-Signature")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Signature", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Content-Sha256", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Date")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Date", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Credential")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Credential", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Security-Token")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Security-Token", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Algorithm")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Algorithm", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-SignedHeaders", valid_613764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613765: Call_DeleteAuthorizer_613753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_613765.validator(path, query, header, formData, body)
  let scheme = call_613765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613765.url(scheme.get, call_613765.host, call_613765.base,
                         call_613765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613765, url, valid)

proc call*(call_613766: Call_DeleteAuthorizer_613753; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_613767 = newJObject()
  add(path_613767, "apiId", newJString(apiId))
  add(path_613767, "authorizerId", newJString(authorizerId))
  result = call_613766.call(path_613767, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_613753(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_613754, base: "/",
    url: url_DeleteAuthorizer_613755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCorsConfiguration_613785 = ref object of OpenApiRestCall_612658
proc url_DeleteCorsConfiguration_613787(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCorsConfiguration_613786(path: JsonNode; query: JsonNode;
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
  var valid_613788 = path.getOrDefault("apiId")
  valid_613788 = validateParameter(valid_613788, JString, required = true,
                                 default = nil)
  if valid_613788 != nil:
    section.add "apiId", valid_613788
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
  var valid_613789 = header.getOrDefault("X-Amz-Signature")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Signature", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Content-Sha256", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Date")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Date", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Credential")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Credential", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Security-Token")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Security-Token", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Algorithm")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Algorithm", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-SignedHeaders", valid_613795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613796: Call_DeleteCorsConfiguration_613785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a CORS configuration.
  ## 
  let valid = call_613796.validator(path, query, header, formData, body)
  let scheme = call_613796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613796.url(scheme.get, call_613796.host, call_613796.base,
                         call_613796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613796, url, valid)

proc call*(call_613797: Call_DeleteCorsConfiguration_613785; apiId: string): Recallable =
  ## deleteCorsConfiguration
  ## Deletes a CORS configuration.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_613798 = newJObject()
  add(path_613798, "apiId", newJString(apiId))
  result = call_613797.call(path_613798, nil, nil, nil, nil)

var deleteCorsConfiguration* = Call_DeleteCorsConfiguration_613785(
    name: "deleteCorsConfiguration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/cors",
    validator: validate_DeleteCorsConfiguration_613786, base: "/",
    url: url_DeleteCorsConfiguration_613787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_613799 = ref object of OpenApiRestCall_612658
proc url_GetDeployment_613801(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_613800(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613802 = path.getOrDefault("apiId")
  valid_613802 = validateParameter(valid_613802, JString, required = true,
                                 default = nil)
  if valid_613802 != nil:
    section.add "apiId", valid_613802
  var valid_613803 = path.getOrDefault("deploymentId")
  valid_613803 = validateParameter(valid_613803, JString, required = true,
                                 default = nil)
  if valid_613803 != nil:
    section.add "deploymentId", valid_613803
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
  var valid_613804 = header.getOrDefault("X-Amz-Signature")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Signature", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Content-Sha256", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Date")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Date", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Credential")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Credential", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Security-Token")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Security-Token", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Algorithm")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Algorithm", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-SignedHeaders", valid_613810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613811: Call_GetDeployment_613799; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_613811.validator(path, query, header, formData, body)
  let scheme = call_613811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613811.url(scheme.get, call_613811.host, call_613811.base,
                         call_613811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613811, url, valid)

proc call*(call_613812: Call_GetDeployment_613799; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_613813 = newJObject()
  add(path_613813, "apiId", newJString(apiId))
  add(path_613813, "deploymentId", newJString(deploymentId))
  result = call_613812.call(path_613813, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_613799(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_613800, base: "/", url: url_GetDeployment_613801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_613829 = ref object of OpenApiRestCall_612658
proc url_UpdateDeployment_613831(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeployment_613830(path: JsonNode; query: JsonNode;
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
  var valid_613832 = path.getOrDefault("apiId")
  valid_613832 = validateParameter(valid_613832, JString, required = true,
                                 default = nil)
  if valid_613832 != nil:
    section.add "apiId", valid_613832
  var valid_613833 = path.getOrDefault("deploymentId")
  valid_613833 = validateParameter(valid_613833, JString, required = true,
                                 default = nil)
  if valid_613833 != nil:
    section.add "deploymentId", valid_613833
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
  var valid_613834 = header.getOrDefault("X-Amz-Signature")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Signature", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Content-Sha256", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Date")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Date", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Credential")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Credential", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-Security-Token")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-Security-Token", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Algorithm")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Algorithm", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-SignedHeaders", valid_613840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613842: Call_UpdateDeployment_613829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_613842.validator(path, query, header, formData, body)
  let scheme = call_613842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613842.url(scheme.get, call_613842.host, call_613842.base,
                         call_613842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613842, url, valid)

proc call*(call_613843: Call_UpdateDeployment_613829; apiId: string; body: JsonNode;
          deploymentId: string): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_613844 = newJObject()
  var body_613845 = newJObject()
  add(path_613844, "apiId", newJString(apiId))
  if body != nil:
    body_613845 = body
  add(path_613844, "deploymentId", newJString(deploymentId))
  result = call_613843.call(path_613844, nil, nil, nil, body_613845)

var updateDeployment* = Call_UpdateDeployment_613829(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_613830, base: "/",
    url: url_UpdateDeployment_613831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_613814 = ref object of OpenApiRestCall_612658
proc url_DeleteDeployment_613816(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeployment_613815(path: JsonNode; query: JsonNode;
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
  var valid_613817 = path.getOrDefault("apiId")
  valid_613817 = validateParameter(valid_613817, JString, required = true,
                                 default = nil)
  if valid_613817 != nil:
    section.add "apiId", valid_613817
  var valid_613818 = path.getOrDefault("deploymentId")
  valid_613818 = validateParameter(valid_613818, JString, required = true,
                                 default = nil)
  if valid_613818 != nil:
    section.add "deploymentId", valid_613818
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
  var valid_613819 = header.getOrDefault("X-Amz-Signature")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Signature", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Content-Sha256", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Date")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Date", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Credential")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Credential", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Security-Token")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Security-Token", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Algorithm")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Algorithm", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-SignedHeaders", valid_613825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613826: Call_DeleteDeployment_613814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_613826.validator(path, query, header, formData, body)
  let scheme = call_613826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613826.url(scheme.get, call_613826.host, call_613826.base,
                         call_613826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613826, url, valid)

proc call*(call_613827: Call_DeleteDeployment_613814; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_613828 = newJObject()
  add(path_613828, "apiId", newJString(apiId))
  add(path_613828, "deploymentId", newJString(deploymentId))
  result = call_613827.call(path_613828, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_613814(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_613815, base: "/",
    url: url_DeleteDeployment_613816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_613846 = ref object of OpenApiRestCall_612658
proc url_GetDomainName_613848(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainName_613847(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613849 = path.getOrDefault("domainName")
  valid_613849 = validateParameter(valid_613849, JString, required = true,
                                 default = nil)
  if valid_613849 != nil:
    section.add "domainName", valid_613849
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
  var valid_613850 = header.getOrDefault("X-Amz-Signature")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Signature", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Content-Sha256", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Date")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Date", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Credential")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Credential", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Security-Token")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Security-Token", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Algorithm")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Algorithm", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-SignedHeaders", valid_613856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613857: Call_GetDomainName_613846; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_613857.validator(path, query, header, formData, body)
  let scheme = call_613857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613857.url(scheme.get, call_613857.host, call_613857.base,
                         call_613857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613857, url, valid)

proc call*(call_613858: Call_GetDomainName_613846; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_613859 = newJObject()
  add(path_613859, "domainName", newJString(domainName))
  result = call_613858.call(path_613859, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_613846(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_613847,
    base: "/", url: url_GetDomainName_613848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_613874 = ref object of OpenApiRestCall_612658
proc url_UpdateDomainName_613876(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainName_613875(path: JsonNode; query: JsonNode;
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
  var valid_613877 = path.getOrDefault("domainName")
  valid_613877 = validateParameter(valid_613877, JString, required = true,
                                 default = nil)
  if valid_613877 != nil:
    section.add "domainName", valid_613877
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
  var valid_613878 = header.getOrDefault("X-Amz-Signature")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Signature", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Content-Sha256", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Date")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Date", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Credential")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Credential", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Security-Token")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Security-Token", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Algorithm")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Algorithm", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-SignedHeaders", valid_613884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613886: Call_UpdateDomainName_613874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_613886.validator(path, query, header, formData, body)
  let scheme = call_613886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613886.url(scheme.get, call_613886.host, call_613886.base,
                         call_613886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613886, url, valid)

proc call*(call_613887: Call_UpdateDomainName_613874; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_613888 = newJObject()
  var body_613889 = newJObject()
  if body != nil:
    body_613889 = body
  add(path_613888, "domainName", newJString(domainName))
  result = call_613887.call(path_613888, nil, nil, nil, body_613889)

var updateDomainName* = Call_UpdateDomainName_613874(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_613875,
    base: "/", url: url_UpdateDomainName_613876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_613860 = ref object of OpenApiRestCall_612658
proc url_DeleteDomainName_613862(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainName_613861(path: JsonNode; query: JsonNode;
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
  var valid_613863 = path.getOrDefault("domainName")
  valid_613863 = validateParameter(valid_613863, JString, required = true,
                                 default = nil)
  if valid_613863 != nil:
    section.add "domainName", valid_613863
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
  var valid_613864 = header.getOrDefault("X-Amz-Signature")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Signature", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Content-Sha256", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Date")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Date", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Credential")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Credential", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Security-Token")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Security-Token", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Algorithm")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Algorithm", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-SignedHeaders", valid_613870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613871: Call_DeleteDomainName_613860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_613871.validator(path, query, header, formData, body)
  let scheme = call_613871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613871.url(scheme.get, call_613871.host, call_613871.base,
                         call_613871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613871, url, valid)

proc call*(call_613872: Call_DeleteDomainName_613860; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_613873 = newJObject()
  add(path_613873, "domainName", newJString(domainName))
  result = call_613872.call(path_613873, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_613860(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_613861,
    base: "/", url: url_DeleteDomainName_613862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_613890 = ref object of OpenApiRestCall_612658
proc url_GetIntegration_613892(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegration_613891(path: JsonNode; query: JsonNode;
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
  var valid_613893 = path.getOrDefault("apiId")
  valid_613893 = validateParameter(valid_613893, JString, required = true,
                                 default = nil)
  if valid_613893 != nil:
    section.add "apiId", valid_613893
  var valid_613894 = path.getOrDefault("integrationId")
  valid_613894 = validateParameter(valid_613894, JString, required = true,
                                 default = nil)
  if valid_613894 != nil:
    section.add "integrationId", valid_613894
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
  var valid_613895 = header.getOrDefault("X-Amz-Signature")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Signature", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Content-Sha256", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Date")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Date", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Credential")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Credential", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Security-Token")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Security-Token", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Algorithm")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Algorithm", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-SignedHeaders", valid_613901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613902: Call_GetIntegration_613890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_613902.validator(path, query, header, formData, body)
  let scheme = call_613902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613902.url(scheme.get, call_613902.host, call_613902.base,
                         call_613902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613902, url, valid)

proc call*(call_613903: Call_GetIntegration_613890; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_613904 = newJObject()
  add(path_613904, "apiId", newJString(apiId))
  add(path_613904, "integrationId", newJString(integrationId))
  result = call_613903.call(path_613904, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_613890(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_613891, base: "/", url: url_GetIntegration_613892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_613920 = ref object of OpenApiRestCall_612658
proc url_UpdateIntegration_613922(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegration_613921(path: JsonNode; query: JsonNode;
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
  var valid_613923 = path.getOrDefault("apiId")
  valid_613923 = validateParameter(valid_613923, JString, required = true,
                                 default = nil)
  if valid_613923 != nil:
    section.add "apiId", valid_613923
  var valid_613924 = path.getOrDefault("integrationId")
  valid_613924 = validateParameter(valid_613924, JString, required = true,
                                 default = nil)
  if valid_613924 != nil:
    section.add "integrationId", valid_613924
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
  var valid_613925 = header.getOrDefault("X-Amz-Signature")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Signature", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Content-Sha256", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Date")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Date", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Credential")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Credential", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Security-Token")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Security-Token", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Algorithm")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Algorithm", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-SignedHeaders", valid_613931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613933: Call_UpdateIntegration_613920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_613933.validator(path, query, header, formData, body)
  let scheme = call_613933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613933.url(scheme.get, call_613933.host, call_613933.base,
                         call_613933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613933, url, valid)

proc call*(call_613934: Call_UpdateIntegration_613920; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_613935 = newJObject()
  var body_613936 = newJObject()
  add(path_613935, "apiId", newJString(apiId))
  add(path_613935, "integrationId", newJString(integrationId))
  if body != nil:
    body_613936 = body
  result = call_613934.call(path_613935, nil, nil, nil, body_613936)

var updateIntegration* = Call_UpdateIntegration_613920(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_613921, base: "/",
    url: url_UpdateIntegration_613922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_613905 = ref object of OpenApiRestCall_612658
proc url_DeleteIntegration_613907(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegration_613906(path: JsonNode; query: JsonNode;
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
  var valid_613908 = path.getOrDefault("apiId")
  valid_613908 = validateParameter(valid_613908, JString, required = true,
                                 default = nil)
  if valid_613908 != nil:
    section.add "apiId", valid_613908
  var valid_613909 = path.getOrDefault("integrationId")
  valid_613909 = validateParameter(valid_613909, JString, required = true,
                                 default = nil)
  if valid_613909 != nil:
    section.add "integrationId", valid_613909
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
  var valid_613910 = header.getOrDefault("X-Amz-Signature")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Signature", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Content-Sha256", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Date")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Date", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Credential")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Credential", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Security-Token")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Security-Token", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Algorithm")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Algorithm", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-SignedHeaders", valid_613916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613917: Call_DeleteIntegration_613905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_613917.validator(path, query, header, formData, body)
  let scheme = call_613917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613917.url(scheme.get, call_613917.host, call_613917.base,
                         call_613917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613917, url, valid)

proc call*(call_613918: Call_DeleteIntegration_613905; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_613919 = newJObject()
  add(path_613919, "apiId", newJString(apiId))
  add(path_613919, "integrationId", newJString(integrationId))
  result = call_613918.call(path_613919, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_613905(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_613906, base: "/",
    url: url_DeleteIntegration_613907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_613937 = ref object of OpenApiRestCall_612658
proc url_GetIntegrationResponse_613939(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponse_613938(path: JsonNode; query: JsonNode;
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
  var valid_613940 = path.getOrDefault("integrationResponseId")
  valid_613940 = validateParameter(valid_613940, JString, required = true,
                                 default = nil)
  if valid_613940 != nil:
    section.add "integrationResponseId", valid_613940
  var valid_613941 = path.getOrDefault("apiId")
  valid_613941 = validateParameter(valid_613941, JString, required = true,
                                 default = nil)
  if valid_613941 != nil:
    section.add "apiId", valid_613941
  var valid_613942 = path.getOrDefault("integrationId")
  valid_613942 = validateParameter(valid_613942, JString, required = true,
                                 default = nil)
  if valid_613942 != nil:
    section.add "integrationId", valid_613942
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
  var valid_613943 = header.getOrDefault("X-Amz-Signature")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Signature", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Content-Sha256", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Date")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Date", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Credential")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Credential", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Security-Token")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Security-Token", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Algorithm")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Algorithm", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-SignedHeaders", valid_613949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613950: Call_GetIntegrationResponse_613937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_613950.validator(path, query, header, formData, body)
  let scheme = call_613950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613950.url(scheme.get, call_613950.host, call_613950.base,
                         call_613950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613950, url, valid)

proc call*(call_613951: Call_GetIntegrationResponse_613937;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_613952 = newJObject()
  add(path_613952, "integrationResponseId", newJString(integrationResponseId))
  add(path_613952, "apiId", newJString(apiId))
  add(path_613952, "integrationId", newJString(integrationId))
  result = call_613951.call(path_613952, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_613937(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_613938, base: "/",
    url: url_GetIntegrationResponse_613939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_613969 = ref object of OpenApiRestCall_612658
proc url_UpdateIntegrationResponse_613971(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_613970(path: JsonNode; query: JsonNode;
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
  var valid_613972 = path.getOrDefault("integrationResponseId")
  valid_613972 = validateParameter(valid_613972, JString, required = true,
                                 default = nil)
  if valid_613972 != nil:
    section.add "integrationResponseId", valid_613972
  var valid_613973 = path.getOrDefault("apiId")
  valid_613973 = validateParameter(valid_613973, JString, required = true,
                                 default = nil)
  if valid_613973 != nil:
    section.add "apiId", valid_613973
  var valid_613974 = path.getOrDefault("integrationId")
  valid_613974 = validateParameter(valid_613974, JString, required = true,
                                 default = nil)
  if valid_613974 != nil:
    section.add "integrationId", valid_613974
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
  var valid_613975 = header.getOrDefault("X-Amz-Signature")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Signature", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Content-Sha256", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Date")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Date", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Credential")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Credential", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Security-Token")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Security-Token", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Algorithm")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Algorithm", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-SignedHeaders", valid_613981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613983: Call_UpdateIntegrationResponse_613969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_613983.validator(path, query, header, formData, body)
  let scheme = call_613983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613983.url(scheme.get, call_613983.host, call_613983.base,
                         call_613983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613983, url, valid)

proc call*(call_613984: Call_UpdateIntegrationResponse_613969;
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
  var path_613985 = newJObject()
  var body_613986 = newJObject()
  add(path_613985, "integrationResponseId", newJString(integrationResponseId))
  add(path_613985, "apiId", newJString(apiId))
  add(path_613985, "integrationId", newJString(integrationId))
  if body != nil:
    body_613986 = body
  result = call_613984.call(path_613985, nil, nil, nil, body_613986)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_613969(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_613970, base: "/",
    url: url_UpdateIntegrationResponse_613971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_613953 = ref object of OpenApiRestCall_612658
proc url_DeleteIntegrationResponse_613955(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_613954(path: JsonNode; query: JsonNode;
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
  var valid_613956 = path.getOrDefault("integrationResponseId")
  valid_613956 = validateParameter(valid_613956, JString, required = true,
                                 default = nil)
  if valid_613956 != nil:
    section.add "integrationResponseId", valid_613956
  var valid_613957 = path.getOrDefault("apiId")
  valid_613957 = validateParameter(valid_613957, JString, required = true,
                                 default = nil)
  if valid_613957 != nil:
    section.add "apiId", valid_613957
  var valid_613958 = path.getOrDefault("integrationId")
  valid_613958 = validateParameter(valid_613958, JString, required = true,
                                 default = nil)
  if valid_613958 != nil:
    section.add "integrationId", valid_613958
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
  var valid_613959 = header.getOrDefault("X-Amz-Signature")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Signature", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Content-Sha256", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Date")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Date", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Credential")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Credential", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Security-Token")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Security-Token", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Algorithm")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Algorithm", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-SignedHeaders", valid_613965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613966: Call_DeleteIntegrationResponse_613953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_613966.validator(path, query, header, formData, body)
  let scheme = call_613966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613966.url(scheme.get, call_613966.host, call_613966.base,
                         call_613966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613966, url, valid)

proc call*(call_613967: Call_DeleteIntegrationResponse_613953;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_613968 = newJObject()
  add(path_613968, "integrationResponseId", newJString(integrationResponseId))
  add(path_613968, "apiId", newJString(apiId))
  add(path_613968, "integrationId", newJString(integrationId))
  result = call_613967.call(path_613968, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_613953(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_613954, base: "/",
    url: url_DeleteIntegrationResponse_613955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_613987 = ref object of OpenApiRestCall_612658
proc url_GetModel_613989(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModel_613988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613990 = path.getOrDefault("apiId")
  valid_613990 = validateParameter(valid_613990, JString, required = true,
                                 default = nil)
  if valid_613990 != nil:
    section.add "apiId", valid_613990
  var valid_613991 = path.getOrDefault("modelId")
  valid_613991 = validateParameter(valid_613991, JString, required = true,
                                 default = nil)
  if valid_613991 != nil:
    section.add "modelId", valid_613991
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
  var valid_613992 = header.getOrDefault("X-Amz-Signature")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Signature", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Content-Sha256", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Date")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Date", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Credential")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Credential", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Security-Token")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Security-Token", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Algorithm")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Algorithm", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-SignedHeaders", valid_613998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613999: Call_GetModel_613987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_613999.validator(path, query, header, formData, body)
  let scheme = call_613999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613999.url(scheme.get, call_613999.host, call_613999.base,
                         call_613999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613999, url, valid)

proc call*(call_614000: Call_GetModel_613987; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_614001 = newJObject()
  add(path_614001, "apiId", newJString(apiId))
  add(path_614001, "modelId", newJString(modelId))
  result = call_614000.call(path_614001, nil, nil, nil, nil)

var getModel* = Call_GetModel_613987(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_613988, base: "/",
                                  url: url_GetModel_613989,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_614017 = ref object of OpenApiRestCall_612658
proc url_UpdateModel_614019(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateModel_614018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614020 = path.getOrDefault("apiId")
  valid_614020 = validateParameter(valid_614020, JString, required = true,
                                 default = nil)
  if valid_614020 != nil:
    section.add "apiId", valid_614020
  var valid_614021 = path.getOrDefault("modelId")
  valid_614021 = validateParameter(valid_614021, JString, required = true,
                                 default = nil)
  if valid_614021 != nil:
    section.add "modelId", valid_614021
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
  var valid_614022 = header.getOrDefault("X-Amz-Signature")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Signature", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Content-Sha256", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Date")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Date", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Credential")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Credential", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Security-Token")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Security-Token", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Algorithm")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Algorithm", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-SignedHeaders", valid_614028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614030: Call_UpdateModel_614017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_614030.validator(path, query, header, formData, body)
  let scheme = call_614030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614030.url(scheme.get, call_614030.host, call_614030.base,
                         call_614030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614030, url, valid)

proc call*(call_614031: Call_UpdateModel_614017; apiId: string; body: JsonNode;
          modelId: string): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   modelId: string (required)
  ##          : The model ID.
  var path_614032 = newJObject()
  var body_614033 = newJObject()
  add(path_614032, "apiId", newJString(apiId))
  if body != nil:
    body_614033 = body
  add(path_614032, "modelId", newJString(modelId))
  result = call_614031.call(path_614032, nil, nil, nil, body_614033)

var updateModel* = Call_UpdateModel_614017(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_614018,
                                        base: "/", url: url_UpdateModel_614019,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_614002 = ref object of OpenApiRestCall_612658
proc url_DeleteModel_614004(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteModel_614003(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614005 = path.getOrDefault("apiId")
  valid_614005 = validateParameter(valid_614005, JString, required = true,
                                 default = nil)
  if valid_614005 != nil:
    section.add "apiId", valid_614005
  var valid_614006 = path.getOrDefault("modelId")
  valid_614006 = validateParameter(valid_614006, JString, required = true,
                                 default = nil)
  if valid_614006 != nil:
    section.add "modelId", valid_614006
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
  var valid_614007 = header.getOrDefault("X-Amz-Signature")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Signature", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Content-Sha256", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Date")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Date", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Credential")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Credential", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Security-Token")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Security-Token", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Algorithm")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Algorithm", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-SignedHeaders", valid_614013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614014: Call_DeleteModel_614002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_614014.validator(path, query, header, formData, body)
  let scheme = call_614014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614014.url(scheme.get, call_614014.host, call_614014.base,
                         call_614014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614014, url, valid)

proc call*(call_614015: Call_DeleteModel_614002; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_614016 = newJObject()
  add(path_614016, "apiId", newJString(apiId))
  add(path_614016, "modelId", newJString(modelId))
  result = call_614015.call(path_614016, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_614002(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_614003,
                                        base: "/", url: url_DeleteModel_614004,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_614034 = ref object of OpenApiRestCall_612658
proc url_GetRoute_614036(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoute_614035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614037 = path.getOrDefault("apiId")
  valid_614037 = validateParameter(valid_614037, JString, required = true,
                                 default = nil)
  if valid_614037 != nil:
    section.add "apiId", valid_614037
  var valid_614038 = path.getOrDefault("routeId")
  valid_614038 = validateParameter(valid_614038, JString, required = true,
                                 default = nil)
  if valid_614038 != nil:
    section.add "routeId", valid_614038
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
  var valid_614039 = header.getOrDefault("X-Amz-Signature")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Signature", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Content-Sha256", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Date")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Date", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Credential")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Credential", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Security-Token")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Security-Token", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Algorithm")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Algorithm", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-SignedHeaders", valid_614045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614046: Call_GetRoute_614034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_614046.validator(path, query, header, formData, body)
  let scheme = call_614046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614046.url(scheme.get, call_614046.host, call_614046.base,
                         call_614046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614046, url, valid)

proc call*(call_614047: Call_GetRoute_614034; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_614048 = newJObject()
  add(path_614048, "apiId", newJString(apiId))
  add(path_614048, "routeId", newJString(routeId))
  result = call_614047.call(path_614048, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_614034(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_614035, base: "/",
                                  url: url_GetRoute_614036,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_614064 = ref object of OpenApiRestCall_612658
proc url_UpdateRoute_614066(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoute_614065(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614067 = path.getOrDefault("apiId")
  valid_614067 = validateParameter(valid_614067, JString, required = true,
                                 default = nil)
  if valid_614067 != nil:
    section.add "apiId", valid_614067
  var valid_614068 = path.getOrDefault("routeId")
  valid_614068 = validateParameter(valid_614068, JString, required = true,
                                 default = nil)
  if valid_614068 != nil:
    section.add "routeId", valid_614068
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
  var valid_614069 = header.getOrDefault("X-Amz-Signature")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Signature", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Content-Sha256", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-Date")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Date", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-Credential")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-Credential", valid_614072
  var valid_614073 = header.getOrDefault("X-Amz-Security-Token")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "X-Amz-Security-Token", valid_614073
  var valid_614074 = header.getOrDefault("X-Amz-Algorithm")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "X-Amz-Algorithm", valid_614074
  var valid_614075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-SignedHeaders", valid_614075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614077: Call_UpdateRoute_614064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_614077.validator(path, query, header, formData, body)
  let scheme = call_614077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614077.url(scheme.get, call_614077.host, call_614077.base,
                         call_614077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614077, url, valid)

proc call*(call_614078: Call_UpdateRoute_614064; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_614079 = newJObject()
  var body_614080 = newJObject()
  add(path_614079, "apiId", newJString(apiId))
  if body != nil:
    body_614080 = body
  add(path_614079, "routeId", newJString(routeId))
  result = call_614078.call(path_614079, nil, nil, nil, body_614080)

var updateRoute* = Call_UpdateRoute_614064(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_614065,
                                        base: "/", url: url_UpdateRoute_614066,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_614049 = ref object of OpenApiRestCall_612658
proc url_DeleteRoute_614051(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoute_614050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614052 = path.getOrDefault("apiId")
  valid_614052 = validateParameter(valid_614052, JString, required = true,
                                 default = nil)
  if valid_614052 != nil:
    section.add "apiId", valid_614052
  var valid_614053 = path.getOrDefault("routeId")
  valid_614053 = validateParameter(valid_614053, JString, required = true,
                                 default = nil)
  if valid_614053 != nil:
    section.add "routeId", valid_614053
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
  var valid_614054 = header.getOrDefault("X-Amz-Signature")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Signature", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Content-Sha256", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Date")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Date", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Credential")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Credential", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-Security-Token")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Security-Token", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Algorithm")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Algorithm", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-SignedHeaders", valid_614060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614061: Call_DeleteRoute_614049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_614061.validator(path, query, header, formData, body)
  let scheme = call_614061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614061.url(scheme.get, call_614061.host, call_614061.base,
                         call_614061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614061, url, valid)

proc call*(call_614062: Call_DeleteRoute_614049; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_614063 = newJObject()
  add(path_614063, "apiId", newJString(apiId))
  add(path_614063, "routeId", newJString(routeId))
  result = call_614062.call(path_614063, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_614049(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_614050,
                                        base: "/", url: url_DeleteRoute_614051,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_614081 = ref object of OpenApiRestCall_612658
proc url_GetRouteResponse_614083(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponse_614082(path: JsonNode; query: JsonNode;
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
  var valid_614084 = path.getOrDefault("apiId")
  valid_614084 = validateParameter(valid_614084, JString, required = true,
                                 default = nil)
  if valid_614084 != nil:
    section.add "apiId", valid_614084
  var valid_614085 = path.getOrDefault("routeResponseId")
  valid_614085 = validateParameter(valid_614085, JString, required = true,
                                 default = nil)
  if valid_614085 != nil:
    section.add "routeResponseId", valid_614085
  var valid_614086 = path.getOrDefault("routeId")
  valid_614086 = validateParameter(valid_614086, JString, required = true,
                                 default = nil)
  if valid_614086 != nil:
    section.add "routeId", valid_614086
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
  var valid_614087 = header.getOrDefault("X-Amz-Signature")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Signature", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Content-Sha256", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Date")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Date", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Credential")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Credential", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Security-Token")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Security-Token", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Algorithm")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Algorithm", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-SignedHeaders", valid_614093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614094: Call_GetRouteResponse_614081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_614094.validator(path, query, header, formData, body)
  let scheme = call_614094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614094.url(scheme.get, call_614094.host, call_614094.base,
                         call_614094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614094, url, valid)

proc call*(call_614095: Call_GetRouteResponse_614081; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_614096 = newJObject()
  add(path_614096, "apiId", newJString(apiId))
  add(path_614096, "routeResponseId", newJString(routeResponseId))
  add(path_614096, "routeId", newJString(routeId))
  result = call_614095.call(path_614096, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_614081(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_614082, base: "/",
    url: url_GetRouteResponse_614083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_614113 = ref object of OpenApiRestCall_612658
proc url_UpdateRouteResponse_614115(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRouteResponse_614114(path: JsonNode; query: JsonNode;
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
  var valid_614116 = path.getOrDefault("apiId")
  valid_614116 = validateParameter(valid_614116, JString, required = true,
                                 default = nil)
  if valid_614116 != nil:
    section.add "apiId", valid_614116
  var valid_614117 = path.getOrDefault("routeResponseId")
  valid_614117 = validateParameter(valid_614117, JString, required = true,
                                 default = nil)
  if valid_614117 != nil:
    section.add "routeResponseId", valid_614117
  var valid_614118 = path.getOrDefault("routeId")
  valid_614118 = validateParameter(valid_614118, JString, required = true,
                                 default = nil)
  if valid_614118 != nil:
    section.add "routeId", valid_614118
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
  var valid_614119 = header.getOrDefault("X-Amz-Signature")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "X-Amz-Signature", valid_614119
  var valid_614120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "X-Amz-Content-Sha256", valid_614120
  var valid_614121 = header.getOrDefault("X-Amz-Date")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = nil)
  if valid_614121 != nil:
    section.add "X-Amz-Date", valid_614121
  var valid_614122 = header.getOrDefault("X-Amz-Credential")
  valid_614122 = validateParameter(valid_614122, JString, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "X-Amz-Credential", valid_614122
  var valid_614123 = header.getOrDefault("X-Amz-Security-Token")
  valid_614123 = validateParameter(valid_614123, JString, required = false,
                                 default = nil)
  if valid_614123 != nil:
    section.add "X-Amz-Security-Token", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-Algorithm")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-Algorithm", valid_614124
  var valid_614125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "X-Amz-SignedHeaders", valid_614125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614127: Call_UpdateRouteResponse_614113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_614127.validator(path, query, header, formData, body)
  let scheme = call_614127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614127.url(scheme.get, call_614127.host, call_614127.base,
                         call_614127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614127, url, valid)

proc call*(call_614128: Call_UpdateRouteResponse_614113; apiId: string;
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
  var path_614129 = newJObject()
  var body_614130 = newJObject()
  add(path_614129, "apiId", newJString(apiId))
  add(path_614129, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_614130 = body
  add(path_614129, "routeId", newJString(routeId))
  result = call_614128.call(path_614129, nil, nil, nil, body_614130)

var updateRouteResponse* = Call_UpdateRouteResponse_614113(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_614114, base: "/",
    url: url_UpdateRouteResponse_614115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_614097 = ref object of OpenApiRestCall_612658
proc url_DeleteRouteResponse_614099(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteResponse_614098(path: JsonNode; query: JsonNode;
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
  var valid_614100 = path.getOrDefault("apiId")
  valid_614100 = validateParameter(valid_614100, JString, required = true,
                                 default = nil)
  if valid_614100 != nil:
    section.add "apiId", valid_614100
  var valid_614101 = path.getOrDefault("routeResponseId")
  valid_614101 = validateParameter(valid_614101, JString, required = true,
                                 default = nil)
  if valid_614101 != nil:
    section.add "routeResponseId", valid_614101
  var valid_614102 = path.getOrDefault("routeId")
  valid_614102 = validateParameter(valid_614102, JString, required = true,
                                 default = nil)
  if valid_614102 != nil:
    section.add "routeId", valid_614102
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
  var valid_614103 = header.getOrDefault("X-Amz-Signature")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Signature", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Content-Sha256", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Date")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Date", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Credential")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Credential", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Security-Token")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Security-Token", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Algorithm")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Algorithm", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-SignedHeaders", valid_614109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614110: Call_DeleteRouteResponse_614097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_614110.validator(path, query, header, formData, body)
  let scheme = call_614110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614110.url(scheme.get, call_614110.host, call_614110.base,
                         call_614110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614110, url, valid)

proc call*(call_614111: Call_DeleteRouteResponse_614097; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_614112 = newJObject()
  add(path_614112, "apiId", newJString(apiId))
  add(path_614112, "routeResponseId", newJString(routeResponseId))
  add(path_614112, "routeId", newJString(routeId))
  result = call_614111.call(path_614112, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_614097(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_614098, base: "/",
    url: url_DeleteRouteResponse_614099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteSettings_614131 = ref object of OpenApiRestCall_612658
proc url_DeleteRouteSettings_614133(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteSettings_614132(path: JsonNode; query: JsonNode;
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
  var valid_614134 = path.getOrDefault("stageName")
  valid_614134 = validateParameter(valid_614134, JString, required = true,
                                 default = nil)
  if valid_614134 != nil:
    section.add "stageName", valid_614134
  var valid_614135 = path.getOrDefault("routeKey")
  valid_614135 = validateParameter(valid_614135, JString, required = true,
                                 default = nil)
  if valid_614135 != nil:
    section.add "routeKey", valid_614135
  var valid_614136 = path.getOrDefault("apiId")
  valid_614136 = validateParameter(valid_614136, JString, required = true,
                                 default = nil)
  if valid_614136 != nil:
    section.add "apiId", valid_614136
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
  var valid_614137 = header.getOrDefault("X-Amz-Signature")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-Signature", valid_614137
  var valid_614138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614138 = validateParameter(valid_614138, JString, required = false,
                                 default = nil)
  if valid_614138 != nil:
    section.add "X-Amz-Content-Sha256", valid_614138
  var valid_614139 = header.getOrDefault("X-Amz-Date")
  valid_614139 = validateParameter(valid_614139, JString, required = false,
                                 default = nil)
  if valid_614139 != nil:
    section.add "X-Amz-Date", valid_614139
  var valid_614140 = header.getOrDefault("X-Amz-Credential")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-Credential", valid_614140
  var valid_614141 = header.getOrDefault("X-Amz-Security-Token")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Security-Token", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Algorithm")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Algorithm", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-SignedHeaders", valid_614143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614144: Call_DeleteRouteSettings_614131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the RouteSettings for a stage.
  ## 
  let valid = call_614144.validator(path, query, header, formData, body)
  let scheme = call_614144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614144.url(scheme.get, call_614144.host, call_614144.base,
                         call_614144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614144, url, valid)

proc call*(call_614145: Call_DeleteRouteSettings_614131; stageName: string;
          routeKey: string; apiId: string): Recallable =
  ## deleteRouteSettings
  ## Deletes the RouteSettings for a stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   routeKey: string (required)
  ##           : The route key.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_614146 = newJObject()
  add(path_614146, "stageName", newJString(stageName))
  add(path_614146, "routeKey", newJString(routeKey))
  add(path_614146, "apiId", newJString(apiId))
  result = call_614145.call(path_614146, nil, nil, nil, nil)

var deleteRouteSettings* = Call_DeleteRouteSettings_614131(
    name: "deleteRouteSettings", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}",
    validator: validate_DeleteRouteSettings_614132, base: "/",
    url: url_DeleteRouteSettings_614133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_614147 = ref object of OpenApiRestCall_612658
proc url_GetStage_614149(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStage_614148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614150 = path.getOrDefault("stageName")
  valid_614150 = validateParameter(valid_614150, JString, required = true,
                                 default = nil)
  if valid_614150 != nil:
    section.add "stageName", valid_614150
  var valid_614151 = path.getOrDefault("apiId")
  valid_614151 = validateParameter(valid_614151, JString, required = true,
                                 default = nil)
  if valid_614151 != nil:
    section.add "apiId", valid_614151
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
  var valid_614152 = header.getOrDefault("X-Amz-Signature")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-Signature", valid_614152
  var valid_614153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "X-Amz-Content-Sha256", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-Date")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-Date", valid_614154
  var valid_614155 = header.getOrDefault("X-Amz-Credential")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "X-Amz-Credential", valid_614155
  var valid_614156 = header.getOrDefault("X-Amz-Security-Token")
  valid_614156 = validateParameter(valid_614156, JString, required = false,
                                 default = nil)
  if valid_614156 != nil:
    section.add "X-Amz-Security-Token", valid_614156
  var valid_614157 = header.getOrDefault("X-Amz-Algorithm")
  valid_614157 = validateParameter(valid_614157, JString, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "X-Amz-Algorithm", valid_614157
  var valid_614158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614158 = validateParameter(valid_614158, JString, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "X-Amz-SignedHeaders", valid_614158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614159: Call_GetStage_614147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_614159.validator(path, query, header, formData, body)
  let scheme = call_614159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614159.url(scheme.get, call_614159.host, call_614159.base,
                         call_614159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614159, url, valid)

proc call*(call_614160: Call_GetStage_614147; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_614161 = newJObject()
  add(path_614161, "stageName", newJString(stageName))
  add(path_614161, "apiId", newJString(apiId))
  result = call_614160.call(path_614161, nil, nil, nil, nil)

var getStage* = Call_GetStage_614147(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_614148, base: "/",
                                  url: url_GetStage_614149,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_614177 = ref object of OpenApiRestCall_612658
proc url_UpdateStage_614179(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStage_614178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614180 = path.getOrDefault("stageName")
  valid_614180 = validateParameter(valid_614180, JString, required = true,
                                 default = nil)
  if valid_614180 != nil:
    section.add "stageName", valid_614180
  var valid_614181 = path.getOrDefault("apiId")
  valid_614181 = validateParameter(valid_614181, JString, required = true,
                                 default = nil)
  if valid_614181 != nil:
    section.add "apiId", valid_614181
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
  var valid_614182 = header.getOrDefault("X-Amz-Signature")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Signature", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Content-Sha256", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Date")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Date", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-Credential")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-Credential", valid_614185
  var valid_614186 = header.getOrDefault("X-Amz-Security-Token")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "X-Amz-Security-Token", valid_614186
  var valid_614187 = header.getOrDefault("X-Amz-Algorithm")
  valid_614187 = validateParameter(valid_614187, JString, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "X-Amz-Algorithm", valid_614187
  var valid_614188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614188 = validateParameter(valid_614188, JString, required = false,
                                 default = nil)
  if valid_614188 != nil:
    section.add "X-Amz-SignedHeaders", valid_614188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614190: Call_UpdateStage_614177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_614190.validator(path, query, header, formData, body)
  let scheme = call_614190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614190.url(scheme.get, call_614190.host, call_614190.base,
                         call_614190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614190, url, valid)

proc call*(call_614191: Call_UpdateStage_614177; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_614192 = newJObject()
  var body_614193 = newJObject()
  add(path_614192, "stageName", newJString(stageName))
  add(path_614192, "apiId", newJString(apiId))
  if body != nil:
    body_614193 = body
  result = call_614191.call(path_614192, nil, nil, nil, body_614193)

var updateStage* = Call_UpdateStage_614177(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_614178,
                                        base: "/", url: url_UpdateStage_614179,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_614162 = ref object of OpenApiRestCall_612658
proc url_DeleteStage_614164(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStage_614163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614165 = path.getOrDefault("stageName")
  valid_614165 = validateParameter(valid_614165, JString, required = true,
                                 default = nil)
  if valid_614165 != nil:
    section.add "stageName", valid_614165
  var valid_614166 = path.getOrDefault("apiId")
  valid_614166 = validateParameter(valid_614166, JString, required = true,
                                 default = nil)
  if valid_614166 != nil:
    section.add "apiId", valid_614166
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
  var valid_614167 = header.getOrDefault("X-Amz-Signature")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Signature", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-Content-Sha256", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-Date")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-Date", valid_614169
  var valid_614170 = header.getOrDefault("X-Amz-Credential")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-Credential", valid_614170
  var valid_614171 = header.getOrDefault("X-Amz-Security-Token")
  valid_614171 = validateParameter(valid_614171, JString, required = false,
                                 default = nil)
  if valid_614171 != nil:
    section.add "X-Amz-Security-Token", valid_614171
  var valid_614172 = header.getOrDefault("X-Amz-Algorithm")
  valid_614172 = validateParameter(valid_614172, JString, required = false,
                                 default = nil)
  if valid_614172 != nil:
    section.add "X-Amz-Algorithm", valid_614172
  var valid_614173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614173 = validateParameter(valid_614173, JString, required = false,
                                 default = nil)
  if valid_614173 != nil:
    section.add "X-Amz-SignedHeaders", valid_614173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614174: Call_DeleteStage_614162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_614174.validator(path, query, header, formData, body)
  let scheme = call_614174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614174.url(scheme.get, call_614174.host, call_614174.base,
                         call_614174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614174, url, valid)

proc call*(call_614175: Call_DeleteStage_614162; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_614176 = newJObject()
  add(path_614176, "stageName", newJString(stageName))
  add(path_614176, "apiId", newJString(apiId))
  result = call_614175.call(path_614176, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_614162(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_614163,
                                        base: "/", url: url_DeleteStage_614164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_614194 = ref object of OpenApiRestCall_612658
proc url_GetModelTemplate_614196(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModelTemplate_614195(path: JsonNode; query: JsonNode;
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
  var valid_614197 = path.getOrDefault("apiId")
  valid_614197 = validateParameter(valid_614197, JString, required = true,
                                 default = nil)
  if valid_614197 != nil:
    section.add "apiId", valid_614197
  var valid_614198 = path.getOrDefault("modelId")
  valid_614198 = validateParameter(valid_614198, JString, required = true,
                                 default = nil)
  if valid_614198 != nil:
    section.add "modelId", valid_614198
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
  var valid_614199 = header.getOrDefault("X-Amz-Signature")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Signature", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Content-Sha256", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Date")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Date", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-Credential")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-Credential", valid_614202
  var valid_614203 = header.getOrDefault("X-Amz-Security-Token")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-Security-Token", valid_614203
  var valid_614204 = header.getOrDefault("X-Amz-Algorithm")
  valid_614204 = validateParameter(valid_614204, JString, required = false,
                                 default = nil)
  if valid_614204 != nil:
    section.add "X-Amz-Algorithm", valid_614204
  var valid_614205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "X-Amz-SignedHeaders", valid_614205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614206: Call_GetModelTemplate_614194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_614206.validator(path, query, header, formData, body)
  let scheme = call_614206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614206.url(scheme.get, call_614206.host, call_614206.base,
                         call_614206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614206, url, valid)

proc call*(call_614207: Call_GetModelTemplate_614194; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_614208 = newJObject()
  add(path_614208, "apiId", newJString(apiId))
  add(path_614208, "modelId", newJString(modelId))
  result = call_614207.call(path_614208, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_614194(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_614195, base: "/",
    url: url_GetModelTemplate_614196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614223 = ref object of OpenApiRestCall_612658
proc url_TagResource_614225(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_614224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614226 = path.getOrDefault("resource-arn")
  valid_614226 = validateParameter(valid_614226, JString, required = true,
                                 default = nil)
  if valid_614226 != nil:
    section.add "resource-arn", valid_614226
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
  var valid_614227 = header.getOrDefault("X-Amz-Signature")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Signature", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-Content-Sha256", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Date")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Date", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Credential")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Credential", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-Security-Token")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Security-Token", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-Algorithm")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-Algorithm", valid_614232
  var valid_614233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "X-Amz-SignedHeaders", valid_614233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614235: Call_TagResource_614223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Tag resource to represent a tag.
  ## 
  let valid = call_614235.validator(path, query, header, formData, body)
  let scheme = call_614235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614235.url(scheme.get, call_614235.host, call_614235.base,
                         call_614235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614235, url, valid)

proc call*(call_614236: Call_TagResource_614223; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a new Tag resource to represent a tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   body: JObject (required)
  var path_614237 = newJObject()
  var body_614238 = newJObject()
  add(path_614237, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_614238 = body
  result = call_614236.call(path_614237, nil, nil, nil, body_614238)

var tagResource* = Call_TagResource_614223(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_614224,
                                        base: "/", url: url_TagResource_614225,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_614209 = ref object of OpenApiRestCall_612658
proc url_GetTags_614211(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTags_614210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614212 = path.getOrDefault("resource-arn")
  valid_614212 = validateParameter(valid_614212, JString, required = true,
                                 default = nil)
  if valid_614212 != nil:
    section.add "resource-arn", valid_614212
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
  var valid_614213 = header.getOrDefault("X-Amz-Signature")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Signature", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Content-Sha256", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Date")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Date", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Credential")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Credential", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-Security-Token")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-Security-Token", valid_614217
  var valid_614218 = header.getOrDefault("X-Amz-Algorithm")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-Algorithm", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-SignedHeaders", valid_614219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614220: Call_GetTags_614209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Tag resources.
  ## 
  let valid = call_614220.validator(path, query, header, formData, body)
  let scheme = call_614220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614220.url(scheme.get, call_614220.host, call_614220.base,
                         call_614220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614220, url, valid)

proc call*(call_614221: Call_GetTags_614209; resourceArn: string): Recallable =
  ## getTags
  ## Gets a collection of Tag resources.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  var path_614222 = newJObject()
  add(path_614222, "resource-arn", newJString(resourceArn))
  result = call_614221.call(path_614222, nil, nil, nil, nil)

var getTags* = Call_GetTags_614209(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_614210, base: "/",
                                url: url_GetTags_614211,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614239 = ref object of OpenApiRestCall_612658
proc url_UntagResource_614241(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_614240(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614242 = path.getOrDefault("resource-arn")
  valid_614242 = validateParameter(valid_614242, JString, required = true,
                                 default = nil)
  if valid_614242 != nil:
    section.add "resource-arn", valid_614242
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_614243 = query.getOrDefault("tagKeys")
  valid_614243 = validateParameter(valid_614243, JArray, required = true, default = nil)
  if valid_614243 != nil:
    section.add "tagKeys", valid_614243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614244 = header.getOrDefault("X-Amz-Signature")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Signature", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Content-Sha256", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Date")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Date", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-Credential")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-Credential", valid_614247
  var valid_614248 = header.getOrDefault("X-Amz-Security-Token")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "X-Amz-Security-Token", valid_614248
  var valid_614249 = header.getOrDefault("X-Amz-Algorithm")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-Algorithm", valid_614249
  var valid_614250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-SignedHeaders", valid_614250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614251: Call_UntagResource_614239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Tag.
  ## 
  let valid = call_614251.validator(path, query, header, formData, body)
  let scheme = call_614251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614251.url(scheme.get, call_614251.host, call_614251.base,
                         call_614251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614251, url, valid)

proc call*(call_614252: Call_UntagResource_614239; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a Tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  var path_614253 = newJObject()
  var query_614254 = newJObject()
  add(path_614253, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_614254.add "tagKeys", tagKeys
  result = call_614252.call(path_614253, query_614254, nil, nil, nil)

var untagResource* = Call_UntagResource_614239(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_614240,
    base: "/", url: url_UntagResource_614241, schemes: {Scheme.Https, Scheme.Http})
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
