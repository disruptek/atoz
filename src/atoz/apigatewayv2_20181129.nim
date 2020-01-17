
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
  Call_ImportApi_606184 = ref object of OpenApiRestCall_605589
proc url_ImportApi_606186(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ImportApi_606185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606187 = query.getOrDefault("failOnWarnings")
  valid_606187 = validateParameter(valid_606187, JBool, required = false, default = nil)
  if valid_606187 != nil:
    section.add "failOnWarnings", valid_606187
  var valid_606188 = query.getOrDefault("basepath")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "basepath", valid_606188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606189 = header.getOrDefault("X-Amz-Signature")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Signature", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Content-Sha256", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Date")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Date", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Credential")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Credential", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Security-Token")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Security-Token", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Algorithm")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Algorithm", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-SignedHeaders", valid_606195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606197: Call_ImportApi_606184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an API.
  ## 
  let valid = call_606197.validator(path, query, header, formData, body)
  let scheme = call_606197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606197.url(scheme.get, call_606197.host, call_606197.base,
                         call_606197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606197, url, valid)

proc call*(call_606198: Call_ImportApi_606184; body: JsonNode;
          failOnWarnings: bool = false; basepath: string = ""): Recallable =
  ## importApi
  ## Imports an API.
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   body: JObject (required)
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  var query_606199 = newJObject()
  var body_606200 = newJObject()
  add(query_606199, "failOnWarnings", newJBool(failOnWarnings))
  if body != nil:
    body_606200 = body
  add(query_606199, "basepath", newJString(basepath))
  result = call_606198.call(nil, query_606199, nil, nil, body_606200)

var importApi* = Call_ImportApi_606184(name: "importApi", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_ImportApi_606185,
                                    base: "/", url: url_ImportApi_606186,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApi_606201 = ref object of OpenApiRestCall_605589
proc url_CreateApi_606203(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApi_606202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606204 = header.getOrDefault("X-Amz-Signature")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Signature", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Content-Sha256", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Date")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Date", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Credential")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Credential", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Security-Token")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Security-Token", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Algorithm")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Algorithm", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-SignedHeaders", valid_606210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606212: Call_CreateApi_606201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_606212.validator(path, query, header, formData, body)
  let scheme = call_606212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606212.url(scheme.get, call_606212.host, call_606212.base,
                         call_606212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606212, url, valid)

proc call*(call_606213: Call_CreateApi_606201; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_606214 = newJObject()
  if body != nil:
    body_606214 = body
  result = call_606213.call(nil, nil, nil, nil, body_606214)

var createApi* = Call_CreateApi_606201(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_606202,
                                    base: "/", url: url_CreateApi_606203,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_605927 = ref object of OpenApiRestCall_605589
proc url_GetApis_605929(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApis_605928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606042 = query.getOrDefault("maxResults")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "maxResults", valid_606042
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606043 = header.getOrDefault("X-Amz-Signature")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Signature", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Content-Sha256", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Date")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Date", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Credential")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Credential", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Security-Token")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Security-Token", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Algorithm")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Algorithm", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-SignedHeaders", valid_606049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606072: Call_GetApis_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_606072.validator(path, query, header, formData, body)
  let scheme = call_606072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606072.url(scheme.get, call_606072.host, call_606072.base,
                         call_606072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606072, url, valid)

proc call*(call_606143: Call_GetApis_605927; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_606144 = newJObject()
  add(query_606144, "nextToken", newJString(nextToken))
  add(query_606144, "maxResults", newJString(maxResults))
  result = call_606143.call(nil, query_606144, nil, nil, nil)

var getApis* = Call_GetApis_605927(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_605928,
                                base: "/", url: url_GetApis_605929,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_606246 = ref object of OpenApiRestCall_605589
proc url_CreateApiMapping_606248(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiMapping_606247(path: JsonNode; query: JsonNode;
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
  var valid_606249 = path.getOrDefault("domainName")
  valid_606249 = validateParameter(valid_606249, JString, required = true,
                                 default = nil)
  if valid_606249 != nil:
    section.add "domainName", valid_606249
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

proc call*(call_606258: Call_CreateApiMapping_606246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_606258.validator(path, query, header, formData, body)
  let scheme = call_606258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606258.url(scheme.get, call_606258.host, call_606258.base,
                         call_606258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606258, url, valid)

proc call*(call_606259: Call_CreateApiMapping_606246; body: JsonNode;
          domainName: string): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_606260 = newJObject()
  var body_606261 = newJObject()
  if body != nil:
    body_606261 = body
  add(path_606260, "domainName", newJString(domainName))
  result = call_606259.call(path_606260, nil, nil, nil, body_606261)

var createApiMapping* = Call_CreateApiMapping_606246(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_606247, base: "/",
    url: url_CreateApiMapping_606248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_606215 = ref object of OpenApiRestCall_605589
proc url_GetApiMappings_606217(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMappings_606216(path: JsonNode; query: JsonNode;
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
  var valid_606232 = path.getOrDefault("domainName")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = nil)
  if valid_606232 != nil:
    section.add "domainName", valid_606232
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606233 = query.getOrDefault("nextToken")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "nextToken", valid_606233
  var valid_606234 = query.getOrDefault("maxResults")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "maxResults", valid_606234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606235 = header.getOrDefault("X-Amz-Signature")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Signature", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Content-Sha256", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Date")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Date", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Credential")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Credential", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Security-Token")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Security-Token", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Algorithm")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Algorithm", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-SignedHeaders", valid_606241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606242: Call_GetApiMappings_606215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets API mappings.
  ## 
  let valid = call_606242.validator(path, query, header, formData, body)
  let scheme = call_606242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606242.url(scheme.get, call_606242.host, call_606242.base,
                         call_606242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606242, url, valid)

proc call*(call_606243: Call_GetApiMappings_606215; domainName: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getApiMappings
  ## Gets API mappings.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_606244 = newJObject()
  var query_606245 = newJObject()
  add(query_606245, "nextToken", newJString(nextToken))
  add(path_606244, "domainName", newJString(domainName))
  add(query_606245, "maxResults", newJString(maxResults))
  result = call_606243.call(path_606244, query_606245, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_606215(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_606216, base: "/", url: url_GetApiMappings_606217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_606279 = ref object of OpenApiRestCall_605589
proc url_CreateAuthorizer_606281(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_606280(path: JsonNode; query: JsonNode;
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
  var valid_606282 = path.getOrDefault("apiId")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "apiId", valid_606282
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
  var valid_606283 = header.getOrDefault("X-Amz-Signature")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Signature", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Content-Sha256", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Date")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Date", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Credential")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Credential", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Security-Token")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Security-Token", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Algorithm")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Algorithm", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-SignedHeaders", valid_606289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_CreateAuthorizer_606279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_CreateAuthorizer_606279; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_606293 = newJObject()
  var body_606294 = newJObject()
  add(path_606293, "apiId", newJString(apiId))
  if body != nil:
    body_606294 = body
  result = call_606292.call(path_606293, nil, nil, nil, body_606294)

var createAuthorizer* = Call_CreateAuthorizer_606279(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_606280,
    base: "/", url: url_CreateAuthorizer_606281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_606262 = ref object of OpenApiRestCall_605589
proc url_GetAuthorizers_606264(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_606263(path: JsonNode; query: JsonNode;
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
  var valid_606265 = path.getOrDefault("apiId")
  valid_606265 = validateParameter(valid_606265, JString, required = true,
                                 default = nil)
  if valid_606265 != nil:
    section.add "apiId", valid_606265
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606266 = query.getOrDefault("nextToken")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "nextToken", valid_606266
  var valid_606267 = query.getOrDefault("maxResults")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "maxResults", valid_606267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606275: Call_GetAuthorizers_606262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_606275.validator(path, query, header, formData, body)
  let scheme = call_606275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606275.url(scheme.get, call_606275.host, call_606275.base,
                         call_606275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606275, url, valid)

proc call*(call_606276: Call_GetAuthorizers_606262; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_606277 = newJObject()
  var query_606278 = newJObject()
  add(query_606278, "nextToken", newJString(nextToken))
  add(path_606277, "apiId", newJString(apiId))
  add(query_606278, "maxResults", newJString(maxResults))
  result = call_606276.call(path_606277, query_606278, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_606262(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_606263,
    base: "/", url: url_GetAuthorizers_606264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_606312 = ref object of OpenApiRestCall_605589
proc url_CreateDeployment_606314(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_606313(path: JsonNode; query: JsonNode;
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
  var valid_606315 = path.getOrDefault("apiId")
  valid_606315 = validateParameter(valid_606315, JString, required = true,
                                 default = nil)
  if valid_606315 != nil:
    section.add "apiId", valid_606315
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
  var valid_606316 = header.getOrDefault("X-Amz-Signature")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Signature", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Content-Sha256", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Date")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Date", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Credential")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Credential", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Security-Token")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Security-Token", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Algorithm")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Algorithm", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-SignedHeaders", valid_606322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606324: Call_CreateDeployment_606312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_606324.validator(path, query, header, formData, body)
  let scheme = call_606324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606324.url(scheme.get, call_606324.host, call_606324.base,
                         call_606324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606324, url, valid)

proc call*(call_606325: Call_CreateDeployment_606312; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_606326 = newJObject()
  var body_606327 = newJObject()
  add(path_606326, "apiId", newJString(apiId))
  if body != nil:
    body_606327 = body
  result = call_606325.call(path_606326, nil, nil, nil, body_606327)

var createDeployment* = Call_CreateDeployment_606312(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_606313,
    base: "/", url: url_CreateDeployment_606314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_606295 = ref object of OpenApiRestCall_605589
proc url_GetDeployments_606297(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_606296(path: JsonNode; query: JsonNode;
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
  var valid_606298 = path.getOrDefault("apiId")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = nil)
  if valid_606298 != nil:
    section.add "apiId", valid_606298
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606299 = query.getOrDefault("nextToken")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "nextToken", valid_606299
  var valid_606300 = query.getOrDefault("maxResults")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "maxResults", valid_606300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606301 = header.getOrDefault("X-Amz-Signature")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Signature", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Content-Sha256", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Date")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Date", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Credential")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Credential", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Security-Token")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Security-Token", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Algorithm")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Algorithm", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-SignedHeaders", valid_606307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606308: Call_GetDeployments_606295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_606308.validator(path, query, header, formData, body)
  let scheme = call_606308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606308.url(scheme.get, call_606308.host, call_606308.base,
                         call_606308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606308, url, valid)

proc call*(call_606309: Call_GetDeployments_606295; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_606310 = newJObject()
  var query_606311 = newJObject()
  add(query_606311, "nextToken", newJString(nextToken))
  add(path_606310, "apiId", newJString(apiId))
  add(query_606311, "maxResults", newJString(maxResults))
  result = call_606309.call(path_606310, query_606311, nil, nil, nil)

var getDeployments* = Call_GetDeployments_606295(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_606296,
    base: "/", url: url_GetDeployments_606297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_606343 = ref object of OpenApiRestCall_605589
proc url_CreateDomainName_606345(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainName_606344(path: JsonNode; query: JsonNode;
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606354: Call_CreateDomainName_606343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_606354.validator(path, query, header, formData, body)
  let scheme = call_606354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606354.url(scheme.get, call_606354.host, call_606354.base,
                         call_606354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606354, url, valid)

proc call*(call_606355: Call_CreateDomainName_606343; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_606356 = newJObject()
  if body != nil:
    body_606356 = body
  result = call_606355.call(nil, nil, nil, nil, body_606356)

var createDomainName* = Call_CreateDomainName_606343(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_606344,
    base: "/", url: url_CreateDomainName_606345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_606328 = ref object of OpenApiRestCall_605589
proc url_GetDomainNames_606330(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainNames_606329(path: JsonNode; query: JsonNode;
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
  var valid_606331 = query.getOrDefault("nextToken")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "nextToken", valid_606331
  var valid_606332 = query.getOrDefault("maxResults")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "maxResults", valid_606332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606333 = header.getOrDefault("X-Amz-Signature")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Signature", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Content-Sha256", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Date")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Date", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Credential")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Credential", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Security-Token")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Security-Token", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Algorithm")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Algorithm", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-SignedHeaders", valid_606339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606340: Call_GetDomainNames_606328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_606340.validator(path, query, header, formData, body)
  let scheme = call_606340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606340.url(scheme.get, call_606340.host, call_606340.base,
                         call_606340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606340, url, valid)

proc call*(call_606341: Call_GetDomainNames_606328; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_606342 = newJObject()
  add(query_606342, "nextToken", newJString(nextToken))
  add(query_606342, "maxResults", newJString(maxResults))
  result = call_606341.call(nil, query_606342, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_606328(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_606329, base: "/",
    url: url_GetDomainNames_606330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_606374 = ref object of OpenApiRestCall_605589
proc url_CreateIntegration_606376(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIntegration_606375(path: JsonNode; query: JsonNode;
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
  var valid_606377 = path.getOrDefault("apiId")
  valid_606377 = validateParameter(valid_606377, JString, required = true,
                                 default = nil)
  if valid_606377 != nil:
    section.add "apiId", valid_606377
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
  var valid_606378 = header.getOrDefault("X-Amz-Signature")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Signature", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Content-Sha256", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Date")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Date", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Credential")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Credential", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Security-Token")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Security-Token", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Algorithm")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Algorithm", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-SignedHeaders", valid_606384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606386: Call_CreateIntegration_606374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_606386.validator(path, query, header, formData, body)
  let scheme = call_606386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606386.url(scheme.get, call_606386.host, call_606386.base,
                         call_606386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606386, url, valid)

proc call*(call_606387: Call_CreateIntegration_606374; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_606388 = newJObject()
  var body_606389 = newJObject()
  add(path_606388, "apiId", newJString(apiId))
  if body != nil:
    body_606389 = body
  result = call_606387.call(path_606388, nil, nil, nil, body_606389)

var createIntegration* = Call_CreateIntegration_606374(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_606375,
    base: "/", url: url_CreateIntegration_606376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_606357 = ref object of OpenApiRestCall_605589
proc url_GetIntegrations_606359(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrations_606358(path: JsonNode; query: JsonNode;
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
  var valid_606360 = path.getOrDefault("apiId")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = nil)
  if valid_606360 != nil:
    section.add "apiId", valid_606360
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606361 = query.getOrDefault("nextToken")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "nextToken", valid_606361
  var valid_606362 = query.getOrDefault("maxResults")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "maxResults", valid_606362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606363 = header.getOrDefault("X-Amz-Signature")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Signature", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Content-Sha256", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Date")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Date", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Credential")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Credential", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Security-Token")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Security-Token", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Algorithm")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Algorithm", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-SignedHeaders", valid_606369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606370: Call_GetIntegrations_606357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_606370.validator(path, query, header, formData, body)
  let scheme = call_606370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606370.url(scheme.get, call_606370.host, call_606370.base,
                         call_606370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606370, url, valid)

proc call*(call_606371: Call_GetIntegrations_606357; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_606372 = newJObject()
  var query_606373 = newJObject()
  add(query_606373, "nextToken", newJString(nextToken))
  add(path_606372, "apiId", newJString(apiId))
  add(query_606373, "maxResults", newJString(maxResults))
  result = call_606371.call(path_606372, query_606373, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_606357(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_606358,
    base: "/", url: url_GetIntegrations_606359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_606408 = ref object of OpenApiRestCall_605589
proc url_CreateIntegrationResponse_606410(protocol: Scheme; host: string;
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

proc validate_CreateIntegrationResponse_606409(path: JsonNode; query: JsonNode;
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
  var valid_606411 = path.getOrDefault("apiId")
  valid_606411 = validateParameter(valid_606411, JString, required = true,
                                 default = nil)
  if valid_606411 != nil:
    section.add "apiId", valid_606411
  var valid_606412 = path.getOrDefault("integrationId")
  valid_606412 = validateParameter(valid_606412, JString, required = true,
                                 default = nil)
  if valid_606412 != nil:
    section.add "integrationId", valid_606412
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
  var valid_606413 = header.getOrDefault("X-Amz-Signature")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Signature", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Content-Sha256", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Date")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Date", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Credential")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Credential", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Security-Token")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Security-Token", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Algorithm")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Algorithm", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-SignedHeaders", valid_606419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606421: Call_CreateIntegrationResponse_606408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_606421.validator(path, query, header, formData, body)
  let scheme = call_606421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606421.url(scheme.get, call_606421.host, call_606421.base,
                         call_606421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606421, url, valid)

proc call*(call_606422: Call_CreateIntegrationResponse_606408; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_606423 = newJObject()
  var body_606424 = newJObject()
  add(path_606423, "apiId", newJString(apiId))
  add(path_606423, "integrationId", newJString(integrationId))
  if body != nil:
    body_606424 = body
  result = call_606422.call(path_606423, nil, nil, nil, body_606424)

var createIntegrationResponse* = Call_CreateIntegrationResponse_606408(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_606409, base: "/",
    url: url_CreateIntegrationResponse_606410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_606390 = ref object of OpenApiRestCall_605589
proc url_GetIntegrationResponses_606392(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponses_606391(path: JsonNode; query: JsonNode;
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
  var valid_606393 = path.getOrDefault("apiId")
  valid_606393 = validateParameter(valid_606393, JString, required = true,
                                 default = nil)
  if valid_606393 != nil:
    section.add "apiId", valid_606393
  var valid_606394 = path.getOrDefault("integrationId")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "integrationId", valid_606394
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606395 = query.getOrDefault("nextToken")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "nextToken", valid_606395
  var valid_606396 = query.getOrDefault("maxResults")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "maxResults", valid_606396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606397 = header.getOrDefault("X-Amz-Signature")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Signature", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Content-Sha256", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Date")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Date", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Credential")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Credential", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Security-Token")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Security-Token", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Algorithm")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Algorithm", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-SignedHeaders", valid_606403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606404: Call_GetIntegrationResponses_606390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_606404.validator(path, query, header, formData, body)
  let scheme = call_606404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606404.url(scheme.get, call_606404.host, call_606404.base,
                         call_606404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606404, url, valid)

proc call*(call_606405: Call_GetIntegrationResponses_606390; apiId: string;
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
  var path_606406 = newJObject()
  var query_606407 = newJObject()
  add(query_606407, "nextToken", newJString(nextToken))
  add(path_606406, "apiId", newJString(apiId))
  add(path_606406, "integrationId", newJString(integrationId))
  add(query_606407, "maxResults", newJString(maxResults))
  result = call_606405.call(path_606406, query_606407, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_606390(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_606391, base: "/",
    url: url_GetIntegrationResponses_606392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_606442 = ref object of OpenApiRestCall_605589
proc url_CreateModel_606444(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_606443(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606445 = path.getOrDefault("apiId")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = nil)
  if valid_606445 != nil:
    section.add "apiId", valid_606445
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
  var valid_606446 = header.getOrDefault("X-Amz-Signature")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Signature", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Content-Sha256", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Date")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Date", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Credential")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Credential", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Security-Token")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Security-Token", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Algorithm")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Algorithm", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-SignedHeaders", valid_606452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606454: Call_CreateModel_606442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_606454.validator(path, query, header, formData, body)
  let scheme = call_606454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606454.url(scheme.get, call_606454.host, call_606454.base,
                         call_606454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606454, url, valid)

proc call*(call_606455: Call_CreateModel_606442; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_606456 = newJObject()
  var body_606457 = newJObject()
  add(path_606456, "apiId", newJString(apiId))
  if body != nil:
    body_606457 = body
  result = call_606455.call(path_606456, nil, nil, nil, body_606457)

var createModel* = Call_CreateModel_606442(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_606443,
                                        base: "/", url: url_CreateModel_606444,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_606425 = ref object of OpenApiRestCall_605589
proc url_GetModels_606427(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_606426(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606428 = path.getOrDefault("apiId")
  valid_606428 = validateParameter(valid_606428, JString, required = true,
                                 default = nil)
  if valid_606428 != nil:
    section.add "apiId", valid_606428
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606429 = query.getOrDefault("nextToken")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "nextToken", valid_606429
  var valid_606430 = query.getOrDefault("maxResults")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "maxResults", valid_606430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606431 = header.getOrDefault("X-Amz-Signature")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Signature", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Content-Sha256", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Date")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Date", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Credential")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Credential", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Security-Token")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Security-Token", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Algorithm")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Algorithm", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-SignedHeaders", valid_606437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606438: Call_GetModels_606425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_606438.validator(path, query, header, formData, body)
  let scheme = call_606438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606438.url(scheme.get, call_606438.host, call_606438.base,
                         call_606438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606438, url, valid)

proc call*(call_606439: Call_GetModels_606425; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_606440 = newJObject()
  var query_606441 = newJObject()
  add(query_606441, "nextToken", newJString(nextToken))
  add(path_606440, "apiId", newJString(apiId))
  add(query_606441, "maxResults", newJString(maxResults))
  result = call_606439.call(path_606440, query_606441, nil, nil, nil)

var getModels* = Call_GetModels_606425(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_606426,
                                    base: "/", url: url_GetModels_606427,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_606475 = ref object of OpenApiRestCall_605589
proc url_CreateRoute_606477(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_606476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606478 = path.getOrDefault("apiId")
  valid_606478 = validateParameter(valid_606478, JString, required = true,
                                 default = nil)
  if valid_606478 != nil:
    section.add "apiId", valid_606478
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606487: Call_CreateRoute_606475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_606487.validator(path, query, header, formData, body)
  let scheme = call_606487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606487.url(scheme.get, call_606487.host, call_606487.base,
                         call_606487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606487, url, valid)

proc call*(call_606488: Call_CreateRoute_606475; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_606489 = newJObject()
  var body_606490 = newJObject()
  add(path_606489, "apiId", newJString(apiId))
  if body != nil:
    body_606490 = body
  result = call_606488.call(path_606489, nil, nil, nil, body_606490)

var createRoute* = Call_CreateRoute_606475(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_606476,
                                        base: "/", url: url_CreateRoute_606477,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_606458 = ref object of OpenApiRestCall_605589
proc url_GetRoutes_606460(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoutes_606459(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606461 = path.getOrDefault("apiId")
  valid_606461 = validateParameter(valid_606461, JString, required = true,
                                 default = nil)
  if valid_606461 != nil:
    section.add "apiId", valid_606461
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606462 = query.getOrDefault("nextToken")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "nextToken", valid_606462
  var valid_606463 = query.getOrDefault("maxResults")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "maxResults", valid_606463
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606464 = header.getOrDefault("X-Amz-Signature")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Signature", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Content-Sha256", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Date")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Date", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Credential")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Credential", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Security-Token")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Security-Token", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Algorithm")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Algorithm", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-SignedHeaders", valid_606470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606471: Call_GetRoutes_606458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_606471.validator(path, query, header, formData, body)
  let scheme = call_606471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606471.url(scheme.get, call_606471.host, call_606471.base,
                         call_606471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606471, url, valid)

proc call*(call_606472: Call_GetRoutes_606458; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_606473 = newJObject()
  var query_606474 = newJObject()
  add(query_606474, "nextToken", newJString(nextToken))
  add(path_606473, "apiId", newJString(apiId))
  add(query_606474, "maxResults", newJString(maxResults))
  result = call_606472.call(path_606473, query_606474, nil, nil, nil)

var getRoutes* = Call_GetRoutes_606458(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_606459,
                                    base: "/", url: url_GetRoutes_606460,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_606509 = ref object of OpenApiRestCall_605589
proc url_CreateRouteResponse_606511(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRouteResponse_606510(path: JsonNode; query: JsonNode;
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
  var valid_606512 = path.getOrDefault("apiId")
  valid_606512 = validateParameter(valid_606512, JString, required = true,
                                 default = nil)
  if valid_606512 != nil:
    section.add "apiId", valid_606512
  var valid_606513 = path.getOrDefault("routeId")
  valid_606513 = validateParameter(valid_606513, JString, required = true,
                                 default = nil)
  if valid_606513 != nil:
    section.add "routeId", valid_606513
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
  var valid_606514 = header.getOrDefault("X-Amz-Signature")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Signature", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Content-Sha256", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Date")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Date", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Credential")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Credential", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Security-Token")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Security-Token", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Algorithm")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Algorithm", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-SignedHeaders", valid_606520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606522: Call_CreateRouteResponse_606509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_606522.validator(path, query, header, formData, body)
  let scheme = call_606522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606522.url(scheme.get, call_606522.host, call_606522.base,
                         call_606522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606522, url, valid)

proc call*(call_606523: Call_CreateRouteResponse_606509; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_606524 = newJObject()
  var body_606525 = newJObject()
  add(path_606524, "apiId", newJString(apiId))
  if body != nil:
    body_606525 = body
  add(path_606524, "routeId", newJString(routeId))
  result = call_606523.call(path_606524, nil, nil, nil, body_606525)

var createRouteResponse* = Call_CreateRouteResponse_606509(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_606510, base: "/",
    url: url_CreateRouteResponse_606511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_606491 = ref object of OpenApiRestCall_605589
proc url_GetRouteResponses_606493(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponses_606492(path: JsonNode; query: JsonNode;
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
  var valid_606494 = path.getOrDefault("apiId")
  valid_606494 = validateParameter(valid_606494, JString, required = true,
                                 default = nil)
  if valid_606494 != nil:
    section.add "apiId", valid_606494
  var valid_606495 = path.getOrDefault("routeId")
  valid_606495 = validateParameter(valid_606495, JString, required = true,
                                 default = nil)
  if valid_606495 != nil:
    section.add "routeId", valid_606495
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606496 = query.getOrDefault("nextToken")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "nextToken", valid_606496
  var valid_606497 = query.getOrDefault("maxResults")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "maxResults", valid_606497
  result.add "query", section
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

proc call*(call_606505: Call_GetRouteResponses_606491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_606505.validator(path, query, header, formData, body)
  let scheme = call_606505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606505.url(scheme.get, call_606505.host, call_606505.base,
                         call_606505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606505, url, valid)

proc call*(call_606506: Call_GetRouteResponses_606491; apiId: string;
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
  var path_606507 = newJObject()
  var query_606508 = newJObject()
  add(query_606508, "nextToken", newJString(nextToken))
  add(path_606507, "apiId", newJString(apiId))
  add(path_606507, "routeId", newJString(routeId))
  add(query_606508, "maxResults", newJString(maxResults))
  result = call_606506.call(path_606507, query_606508, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_606491(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_606492, base: "/",
    url: url_GetRouteResponses_606493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_606543 = ref object of OpenApiRestCall_605589
proc url_CreateStage_606545(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_606544(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606546 = path.getOrDefault("apiId")
  valid_606546 = validateParameter(valid_606546, JString, required = true,
                                 default = nil)
  if valid_606546 != nil:
    section.add "apiId", valid_606546
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

proc call*(call_606555: Call_CreateStage_606543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_606555.validator(path, query, header, formData, body)
  let scheme = call_606555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606555.url(scheme.get, call_606555.host, call_606555.base,
                         call_606555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606555, url, valid)

proc call*(call_606556: Call_CreateStage_606543; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_606557 = newJObject()
  var body_606558 = newJObject()
  add(path_606557, "apiId", newJString(apiId))
  if body != nil:
    body_606558 = body
  result = call_606556.call(path_606557, nil, nil, nil, body_606558)

var createStage* = Call_CreateStage_606543(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_606544,
                                        base: "/", url: url_CreateStage_606545,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_606526 = ref object of OpenApiRestCall_605589
proc url_GetStages_606528(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_606527(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606529 = path.getOrDefault("apiId")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "apiId", valid_606529
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_606530 = query.getOrDefault("nextToken")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "nextToken", valid_606530
  var valid_606531 = query.getOrDefault("maxResults")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "maxResults", valid_606531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606532 = header.getOrDefault("X-Amz-Signature")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Signature", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Content-Sha256", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Date")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Date", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Credential")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Credential", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Security-Token")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Security-Token", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Algorithm")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Algorithm", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-SignedHeaders", valid_606538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606539: Call_GetStages_606526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_606539.validator(path, query, header, formData, body)
  let scheme = call_606539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606539.url(scheme.get, call_606539.host, call_606539.base,
                         call_606539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606539, url, valid)

proc call*(call_606540: Call_GetStages_606526; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_606541 = newJObject()
  var query_606542 = newJObject()
  add(query_606542, "nextToken", newJString(nextToken))
  add(path_606541, "apiId", newJString(apiId))
  add(query_606542, "maxResults", newJString(maxResults))
  result = call_606540.call(path_606541, query_606542, nil, nil, nil)

var getStages* = Call_GetStages_606526(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_606527,
                                    base: "/", url: url_GetStages_606528,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReimportApi_606573 = ref object of OpenApiRestCall_605589
proc url_ReimportApi_606575(protocol: Scheme; host: string; base: string;
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

proc validate_ReimportApi_606574(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606576 = path.getOrDefault("apiId")
  valid_606576 = validateParameter(valid_606576, JString, required = true,
                                 default = nil)
  if valid_606576 != nil:
    section.add "apiId", valid_606576
  result.add "path", section
  ## parameters in `query` object:
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  section = newJObject()
  var valid_606577 = query.getOrDefault("failOnWarnings")
  valid_606577 = validateParameter(valid_606577, JBool, required = false, default = nil)
  if valid_606577 != nil:
    section.add "failOnWarnings", valid_606577
  var valid_606578 = query.getOrDefault("basepath")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "basepath", valid_606578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606579 = header.getOrDefault("X-Amz-Signature")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Signature", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Content-Sha256", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Date")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Date", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Credential")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Credential", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Security-Token")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Security-Token", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Algorithm")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Algorithm", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-SignedHeaders", valid_606585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606587: Call_ReimportApi_606573; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts an Api resource.
  ## 
  let valid = call_606587.validator(path, query, header, formData, body)
  let scheme = call_606587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606587.url(scheme.get, call_606587.host, call_606587.base,
                         call_606587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606587, url, valid)

proc call*(call_606588: Call_ReimportApi_606573; apiId: string; body: JsonNode;
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
  var path_606589 = newJObject()
  var query_606590 = newJObject()
  var body_606591 = newJObject()
  add(query_606590, "failOnWarnings", newJBool(failOnWarnings))
  add(path_606589, "apiId", newJString(apiId))
  if body != nil:
    body_606591 = body
  add(query_606590, "basepath", newJString(basepath))
  result = call_606588.call(path_606589, query_606590, nil, nil, body_606591)

var reimportApi* = Call_ReimportApi_606573(name: "reimportApi",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}",
                                        validator: validate_ReimportApi_606574,
                                        base: "/", url: url_ReimportApi_606575,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_606559 = ref object of OpenApiRestCall_605589
proc url_GetApi_606561(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApi_606560(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606562 = path.getOrDefault("apiId")
  valid_606562 = validateParameter(valid_606562, JString, required = true,
                                 default = nil)
  if valid_606562 != nil:
    section.add "apiId", valid_606562
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
  var valid_606563 = header.getOrDefault("X-Amz-Signature")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Signature", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Content-Sha256", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Date")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Date", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Credential")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Credential", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Security-Token")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Security-Token", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Algorithm")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Algorithm", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-SignedHeaders", valid_606569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606570: Call_GetApi_606559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_606570.validator(path, query, header, formData, body)
  let scheme = call_606570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606570.url(scheme.get, call_606570.host, call_606570.base,
                         call_606570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606570, url, valid)

proc call*(call_606571: Call_GetApi_606559; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_606572 = newJObject()
  add(path_606572, "apiId", newJString(apiId))
  result = call_606571.call(path_606572, nil, nil, nil, nil)

var getApi* = Call_GetApi_606559(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_606560, base: "/",
                              url: url_GetApi_606561,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_606606 = ref object of OpenApiRestCall_605589
proc url_UpdateApi_606608(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApi_606607(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606609 = path.getOrDefault("apiId")
  valid_606609 = validateParameter(valid_606609, JString, required = true,
                                 default = nil)
  if valid_606609 != nil:
    section.add "apiId", valid_606609
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
  var valid_606610 = header.getOrDefault("X-Amz-Signature")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Signature", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Content-Sha256", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Date")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Date", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Credential")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Credential", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Security-Token")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Security-Token", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Algorithm")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Algorithm", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-SignedHeaders", valid_606616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606618: Call_UpdateApi_606606; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_606618.validator(path, query, header, formData, body)
  let scheme = call_606618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606618.url(scheme.get, call_606618.host, call_606618.base,
                         call_606618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606618, url, valid)

proc call*(call_606619: Call_UpdateApi_606606; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_606620 = newJObject()
  var body_606621 = newJObject()
  add(path_606620, "apiId", newJString(apiId))
  if body != nil:
    body_606621 = body
  result = call_606619.call(path_606620, nil, nil, nil, body_606621)

var updateApi* = Call_UpdateApi_606606(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_606607,
                                    base: "/", url: url_UpdateApi_606608,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_606592 = ref object of OpenApiRestCall_605589
proc url_DeleteApi_606594(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApi_606593(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606595 = path.getOrDefault("apiId")
  valid_606595 = validateParameter(valid_606595, JString, required = true,
                                 default = nil)
  if valid_606595 != nil:
    section.add "apiId", valid_606595
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
  var valid_606596 = header.getOrDefault("X-Amz-Signature")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Signature", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Content-Sha256", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Date")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Date", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Credential")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Credential", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Security-Token")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Security-Token", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Algorithm")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Algorithm", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-SignedHeaders", valid_606602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606603: Call_DeleteApi_606592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_606603.validator(path, query, header, formData, body)
  let scheme = call_606603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606603.url(scheme.get, call_606603.host, call_606603.base,
                         call_606603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606603, url, valid)

proc call*(call_606604: Call_DeleteApi_606592; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_606605 = newJObject()
  add(path_606605, "apiId", newJString(apiId))
  result = call_606604.call(path_606605, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_606592(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_606593,
                                    base: "/", url: url_DeleteApi_606594,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_606622 = ref object of OpenApiRestCall_605589
proc url_GetApiMapping_606624(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMapping_606623(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606625 = path.getOrDefault("apiMappingId")
  valid_606625 = validateParameter(valid_606625, JString, required = true,
                                 default = nil)
  if valid_606625 != nil:
    section.add "apiMappingId", valid_606625
  var valid_606626 = path.getOrDefault("domainName")
  valid_606626 = validateParameter(valid_606626, JString, required = true,
                                 default = nil)
  if valid_606626 != nil:
    section.add "domainName", valid_606626
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
  var valid_606627 = header.getOrDefault("X-Amz-Signature")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Signature", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Content-Sha256", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Date")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Date", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Credential")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Credential", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Security-Token")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Security-Token", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Algorithm")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Algorithm", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-SignedHeaders", valid_606633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606634: Call_GetApiMapping_606622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an API mapping.
  ## 
  let valid = call_606634.validator(path, query, header, formData, body)
  let scheme = call_606634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606634.url(scheme.get, call_606634.host, call_606634.base,
                         call_606634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606634, url, valid)

proc call*(call_606635: Call_GetApiMapping_606622; apiMappingId: string;
          domainName: string): Recallable =
  ## getApiMapping
  ## Gets an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_606636 = newJObject()
  add(path_606636, "apiMappingId", newJString(apiMappingId))
  add(path_606636, "domainName", newJString(domainName))
  result = call_606635.call(path_606636, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_606622(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_606623, base: "/", url: url_GetApiMapping_606624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_606652 = ref object of OpenApiRestCall_605589
proc url_UpdateApiMapping_606654(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiMapping_606653(path: JsonNode; query: JsonNode;
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
  var valid_606655 = path.getOrDefault("apiMappingId")
  valid_606655 = validateParameter(valid_606655, JString, required = true,
                                 default = nil)
  if valid_606655 != nil:
    section.add "apiMappingId", valid_606655
  var valid_606656 = path.getOrDefault("domainName")
  valid_606656 = validateParameter(valid_606656, JString, required = true,
                                 default = nil)
  if valid_606656 != nil:
    section.add "domainName", valid_606656
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
  var valid_606657 = header.getOrDefault("X-Amz-Signature")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Signature", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Content-Sha256", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Date")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Date", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Credential")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Credential", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Security-Token")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Security-Token", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Algorithm")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Algorithm", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-SignedHeaders", valid_606663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606665: Call_UpdateApiMapping_606652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_606665.validator(path, query, header, formData, body)
  let scheme = call_606665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606665.url(scheme.get, call_606665.host, call_606665.base,
                         call_606665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606665, url, valid)

proc call*(call_606666: Call_UpdateApiMapping_606652; apiMappingId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_606667 = newJObject()
  var body_606668 = newJObject()
  add(path_606667, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_606668 = body
  add(path_606667, "domainName", newJString(domainName))
  result = call_606666.call(path_606667, nil, nil, nil, body_606668)

var updateApiMapping* = Call_UpdateApiMapping_606652(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_606653, base: "/",
    url: url_UpdateApiMapping_606654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_606637 = ref object of OpenApiRestCall_605589
proc url_DeleteApiMapping_606639(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiMapping_606638(path: JsonNode; query: JsonNode;
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
  var valid_606640 = path.getOrDefault("apiMappingId")
  valid_606640 = validateParameter(valid_606640, JString, required = true,
                                 default = nil)
  if valid_606640 != nil:
    section.add "apiMappingId", valid_606640
  var valid_606641 = path.getOrDefault("domainName")
  valid_606641 = validateParameter(valid_606641, JString, required = true,
                                 default = nil)
  if valid_606641 != nil:
    section.add "domainName", valid_606641
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
  var valid_606642 = header.getOrDefault("X-Amz-Signature")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Signature", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Content-Sha256", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Date")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Date", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Credential")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Credential", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Security-Token")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Security-Token", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Algorithm")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Algorithm", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-SignedHeaders", valid_606648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606649: Call_DeleteApiMapping_606637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_606649.validator(path, query, header, formData, body)
  let scheme = call_606649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606649.url(scheme.get, call_606649.host, call_606649.base,
                         call_606649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606649, url, valid)

proc call*(call_606650: Call_DeleteApiMapping_606637; apiMappingId: string;
          domainName: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_606651 = newJObject()
  add(path_606651, "apiMappingId", newJString(apiMappingId))
  add(path_606651, "domainName", newJString(domainName))
  result = call_606650.call(path_606651, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_606637(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_606638, base: "/",
    url: url_DeleteApiMapping_606639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_606669 = ref object of OpenApiRestCall_605589
proc url_GetAuthorizer_606671(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_606670(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606672 = path.getOrDefault("apiId")
  valid_606672 = validateParameter(valid_606672, JString, required = true,
                                 default = nil)
  if valid_606672 != nil:
    section.add "apiId", valid_606672
  var valid_606673 = path.getOrDefault("authorizerId")
  valid_606673 = validateParameter(valid_606673, JString, required = true,
                                 default = nil)
  if valid_606673 != nil:
    section.add "authorizerId", valid_606673
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
  var valid_606674 = header.getOrDefault("X-Amz-Signature")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Signature", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Content-Sha256", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Date")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Date", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Credential")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Credential", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Security-Token")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Security-Token", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Algorithm")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Algorithm", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-SignedHeaders", valid_606680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606681: Call_GetAuthorizer_606669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_606681.validator(path, query, header, formData, body)
  let scheme = call_606681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606681.url(scheme.get, call_606681.host, call_606681.base,
                         call_606681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606681, url, valid)

proc call*(call_606682: Call_GetAuthorizer_606669; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_606683 = newJObject()
  add(path_606683, "apiId", newJString(apiId))
  add(path_606683, "authorizerId", newJString(authorizerId))
  result = call_606682.call(path_606683, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_606669(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_606670, base: "/", url: url_GetAuthorizer_606671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_606699 = ref object of OpenApiRestCall_605589
proc url_UpdateAuthorizer_606701(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_606700(path: JsonNode; query: JsonNode;
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
  var valid_606702 = path.getOrDefault("apiId")
  valid_606702 = validateParameter(valid_606702, JString, required = true,
                                 default = nil)
  if valid_606702 != nil:
    section.add "apiId", valid_606702
  var valid_606703 = path.getOrDefault("authorizerId")
  valid_606703 = validateParameter(valid_606703, JString, required = true,
                                 default = nil)
  if valid_606703 != nil:
    section.add "authorizerId", valid_606703
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
  var valid_606704 = header.getOrDefault("X-Amz-Signature")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Signature", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Content-Sha256", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Date")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Date", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Credential")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Credential", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Security-Token")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Security-Token", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Algorithm")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Algorithm", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-SignedHeaders", valid_606710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606712: Call_UpdateAuthorizer_606699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_606712.validator(path, query, header, formData, body)
  let scheme = call_606712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606712.url(scheme.get, call_606712.host, call_606712.base,
                         call_606712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606712, url, valid)

proc call*(call_606713: Call_UpdateAuthorizer_606699; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_606714 = newJObject()
  var body_606715 = newJObject()
  add(path_606714, "apiId", newJString(apiId))
  add(path_606714, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_606715 = body
  result = call_606713.call(path_606714, nil, nil, nil, body_606715)

var updateAuthorizer* = Call_UpdateAuthorizer_606699(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_606700, base: "/",
    url: url_UpdateAuthorizer_606701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_606684 = ref object of OpenApiRestCall_605589
proc url_DeleteAuthorizer_606686(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_606685(path: JsonNode; query: JsonNode;
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
  var valid_606687 = path.getOrDefault("apiId")
  valid_606687 = validateParameter(valid_606687, JString, required = true,
                                 default = nil)
  if valid_606687 != nil:
    section.add "apiId", valid_606687
  var valid_606688 = path.getOrDefault("authorizerId")
  valid_606688 = validateParameter(valid_606688, JString, required = true,
                                 default = nil)
  if valid_606688 != nil:
    section.add "authorizerId", valid_606688
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
  var valid_606689 = header.getOrDefault("X-Amz-Signature")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Signature", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Content-Sha256", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Date")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Date", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Credential")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Credential", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-Security-Token")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Security-Token", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Algorithm")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Algorithm", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-SignedHeaders", valid_606695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606696: Call_DeleteAuthorizer_606684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_606696.validator(path, query, header, formData, body)
  let scheme = call_606696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606696.url(scheme.get, call_606696.host, call_606696.base,
                         call_606696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606696, url, valid)

proc call*(call_606697: Call_DeleteAuthorizer_606684; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_606698 = newJObject()
  add(path_606698, "apiId", newJString(apiId))
  add(path_606698, "authorizerId", newJString(authorizerId))
  result = call_606697.call(path_606698, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_606684(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_606685, base: "/",
    url: url_DeleteAuthorizer_606686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCorsConfiguration_606716 = ref object of OpenApiRestCall_605589
proc url_DeleteCorsConfiguration_606718(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCorsConfiguration_606717(path: JsonNode; query: JsonNode;
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
  var valid_606719 = path.getOrDefault("apiId")
  valid_606719 = validateParameter(valid_606719, JString, required = true,
                                 default = nil)
  if valid_606719 != nil:
    section.add "apiId", valid_606719
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
  var valid_606720 = header.getOrDefault("X-Amz-Signature")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Signature", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Content-Sha256", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Date")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Date", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Credential")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Credential", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Security-Token")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Security-Token", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Algorithm")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Algorithm", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-SignedHeaders", valid_606726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606727: Call_DeleteCorsConfiguration_606716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a CORS configuration.
  ## 
  let valid = call_606727.validator(path, query, header, formData, body)
  let scheme = call_606727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606727.url(scheme.get, call_606727.host, call_606727.base,
                         call_606727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606727, url, valid)

proc call*(call_606728: Call_DeleteCorsConfiguration_606716; apiId: string): Recallable =
  ## deleteCorsConfiguration
  ## Deletes a CORS configuration.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_606729 = newJObject()
  add(path_606729, "apiId", newJString(apiId))
  result = call_606728.call(path_606729, nil, nil, nil, nil)

var deleteCorsConfiguration* = Call_DeleteCorsConfiguration_606716(
    name: "deleteCorsConfiguration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/cors",
    validator: validate_DeleteCorsConfiguration_606717, base: "/",
    url: url_DeleteCorsConfiguration_606718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_606730 = ref object of OpenApiRestCall_605589
proc url_GetDeployment_606732(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_606731(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606733 = path.getOrDefault("apiId")
  valid_606733 = validateParameter(valid_606733, JString, required = true,
                                 default = nil)
  if valid_606733 != nil:
    section.add "apiId", valid_606733
  var valid_606734 = path.getOrDefault("deploymentId")
  valid_606734 = validateParameter(valid_606734, JString, required = true,
                                 default = nil)
  if valid_606734 != nil:
    section.add "deploymentId", valid_606734
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
  var valid_606735 = header.getOrDefault("X-Amz-Signature")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Signature", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Content-Sha256", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Date")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Date", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Credential")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Credential", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Security-Token")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Security-Token", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Algorithm")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Algorithm", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-SignedHeaders", valid_606741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606742: Call_GetDeployment_606730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_606742.validator(path, query, header, formData, body)
  let scheme = call_606742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606742.url(scheme.get, call_606742.host, call_606742.base,
                         call_606742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606742, url, valid)

proc call*(call_606743: Call_GetDeployment_606730; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_606744 = newJObject()
  add(path_606744, "apiId", newJString(apiId))
  add(path_606744, "deploymentId", newJString(deploymentId))
  result = call_606743.call(path_606744, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_606730(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_606731, base: "/", url: url_GetDeployment_606732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_606760 = ref object of OpenApiRestCall_605589
proc url_UpdateDeployment_606762(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_606761(path: JsonNode; query: JsonNode;
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
  var valid_606763 = path.getOrDefault("apiId")
  valid_606763 = validateParameter(valid_606763, JString, required = true,
                                 default = nil)
  if valid_606763 != nil:
    section.add "apiId", valid_606763
  var valid_606764 = path.getOrDefault("deploymentId")
  valid_606764 = validateParameter(valid_606764, JString, required = true,
                                 default = nil)
  if valid_606764 != nil:
    section.add "deploymentId", valid_606764
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
  var valid_606765 = header.getOrDefault("X-Amz-Signature")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Signature", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Content-Sha256", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Date")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Date", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Credential")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Credential", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Security-Token")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Security-Token", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Algorithm")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Algorithm", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-SignedHeaders", valid_606771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606773: Call_UpdateDeployment_606760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_606773.validator(path, query, header, formData, body)
  let scheme = call_606773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606773.url(scheme.get, call_606773.host, call_606773.base,
                         call_606773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606773, url, valid)

proc call*(call_606774: Call_UpdateDeployment_606760; apiId: string; body: JsonNode;
          deploymentId: string): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_606775 = newJObject()
  var body_606776 = newJObject()
  add(path_606775, "apiId", newJString(apiId))
  if body != nil:
    body_606776 = body
  add(path_606775, "deploymentId", newJString(deploymentId))
  result = call_606774.call(path_606775, nil, nil, nil, body_606776)

var updateDeployment* = Call_UpdateDeployment_606760(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_606761, base: "/",
    url: url_UpdateDeployment_606762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_606745 = ref object of OpenApiRestCall_605589
proc url_DeleteDeployment_606747(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_606746(path: JsonNode; query: JsonNode;
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
  var valid_606748 = path.getOrDefault("apiId")
  valid_606748 = validateParameter(valid_606748, JString, required = true,
                                 default = nil)
  if valid_606748 != nil:
    section.add "apiId", valid_606748
  var valid_606749 = path.getOrDefault("deploymentId")
  valid_606749 = validateParameter(valid_606749, JString, required = true,
                                 default = nil)
  if valid_606749 != nil:
    section.add "deploymentId", valid_606749
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
  var valid_606750 = header.getOrDefault("X-Amz-Signature")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Signature", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Content-Sha256", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Date")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Date", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Credential")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Credential", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Security-Token")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Security-Token", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Algorithm")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Algorithm", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-SignedHeaders", valid_606756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606757: Call_DeleteDeployment_606745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_606757.validator(path, query, header, formData, body)
  let scheme = call_606757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606757.url(scheme.get, call_606757.host, call_606757.base,
                         call_606757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606757, url, valid)

proc call*(call_606758: Call_DeleteDeployment_606745; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_606759 = newJObject()
  add(path_606759, "apiId", newJString(apiId))
  add(path_606759, "deploymentId", newJString(deploymentId))
  result = call_606758.call(path_606759, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_606745(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_606746, base: "/",
    url: url_DeleteDeployment_606747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_606777 = ref object of OpenApiRestCall_605589
proc url_GetDomainName_606779(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_606778(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606780 = path.getOrDefault("domainName")
  valid_606780 = validateParameter(valid_606780, JString, required = true,
                                 default = nil)
  if valid_606780 != nil:
    section.add "domainName", valid_606780
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
  var valid_606781 = header.getOrDefault("X-Amz-Signature")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Signature", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Content-Sha256", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Date")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Date", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Credential")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Credential", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Security-Token")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Security-Token", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Algorithm")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Algorithm", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-SignedHeaders", valid_606787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606788: Call_GetDomainName_606777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_606788.validator(path, query, header, formData, body)
  let scheme = call_606788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606788.url(scheme.get, call_606788.host, call_606788.base,
                         call_606788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606788, url, valid)

proc call*(call_606789: Call_GetDomainName_606777; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_606790 = newJObject()
  add(path_606790, "domainName", newJString(domainName))
  result = call_606789.call(path_606790, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_606777(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_606778,
    base: "/", url: url_GetDomainName_606779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_606805 = ref object of OpenApiRestCall_605589
proc url_UpdateDomainName_606807(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_606806(path: JsonNode; query: JsonNode;
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
  var valid_606808 = path.getOrDefault("domainName")
  valid_606808 = validateParameter(valid_606808, JString, required = true,
                                 default = nil)
  if valid_606808 != nil:
    section.add "domainName", valid_606808
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
  var valid_606809 = header.getOrDefault("X-Amz-Signature")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Signature", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Content-Sha256", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Date")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Date", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Credential")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Credential", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Security-Token")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Security-Token", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Algorithm")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Algorithm", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-SignedHeaders", valid_606815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606817: Call_UpdateDomainName_606805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_606817.validator(path, query, header, formData, body)
  let scheme = call_606817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606817.url(scheme.get, call_606817.host, call_606817.base,
                         call_606817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606817, url, valid)

proc call*(call_606818: Call_UpdateDomainName_606805; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_606819 = newJObject()
  var body_606820 = newJObject()
  if body != nil:
    body_606820 = body
  add(path_606819, "domainName", newJString(domainName))
  result = call_606818.call(path_606819, nil, nil, nil, body_606820)

var updateDomainName* = Call_UpdateDomainName_606805(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_606806,
    base: "/", url: url_UpdateDomainName_606807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_606791 = ref object of OpenApiRestCall_605589
proc url_DeleteDomainName_606793(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_606792(path: JsonNode; query: JsonNode;
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
  var valid_606794 = path.getOrDefault("domainName")
  valid_606794 = validateParameter(valid_606794, JString, required = true,
                                 default = nil)
  if valid_606794 != nil:
    section.add "domainName", valid_606794
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
  var valid_606795 = header.getOrDefault("X-Amz-Signature")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Signature", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Content-Sha256", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Date")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Date", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Credential")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Credential", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Security-Token")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Security-Token", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Algorithm")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Algorithm", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-SignedHeaders", valid_606801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606802: Call_DeleteDomainName_606791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_606802.validator(path, query, header, formData, body)
  let scheme = call_606802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606802.url(scheme.get, call_606802.host, call_606802.base,
                         call_606802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606802, url, valid)

proc call*(call_606803: Call_DeleteDomainName_606791; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_606804 = newJObject()
  add(path_606804, "domainName", newJString(domainName))
  result = call_606803.call(path_606804, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_606791(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_606792,
    base: "/", url: url_DeleteDomainName_606793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_606821 = ref object of OpenApiRestCall_605589
proc url_GetIntegration_606823(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_606822(path: JsonNode; query: JsonNode;
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
  var valid_606824 = path.getOrDefault("apiId")
  valid_606824 = validateParameter(valid_606824, JString, required = true,
                                 default = nil)
  if valid_606824 != nil:
    section.add "apiId", valid_606824
  var valid_606825 = path.getOrDefault("integrationId")
  valid_606825 = validateParameter(valid_606825, JString, required = true,
                                 default = nil)
  if valid_606825 != nil:
    section.add "integrationId", valid_606825
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
  var valid_606826 = header.getOrDefault("X-Amz-Signature")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Signature", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Content-Sha256", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Date")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Date", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Credential")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Credential", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Security-Token")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Security-Token", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Algorithm")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Algorithm", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-SignedHeaders", valid_606832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606833: Call_GetIntegration_606821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_606833.validator(path, query, header, formData, body)
  let scheme = call_606833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606833.url(scheme.get, call_606833.host, call_606833.base,
                         call_606833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606833, url, valid)

proc call*(call_606834: Call_GetIntegration_606821; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_606835 = newJObject()
  add(path_606835, "apiId", newJString(apiId))
  add(path_606835, "integrationId", newJString(integrationId))
  result = call_606834.call(path_606835, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_606821(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_606822, base: "/", url: url_GetIntegration_606823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_606851 = ref object of OpenApiRestCall_605589
proc url_UpdateIntegration_606853(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_606852(path: JsonNode; query: JsonNode;
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
  var valid_606854 = path.getOrDefault("apiId")
  valid_606854 = validateParameter(valid_606854, JString, required = true,
                                 default = nil)
  if valid_606854 != nil:
    section.add "apiId", valid_606854
  var valid_606855 = path.getOrDefault("integrationId")
  valid_606855 = validateParameter(valid_606855, JString, required = true,
                                 default = nil)
  if valid_606855 != nil:
    section.add "integrationId", valid_606855
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
  var valid_606856 = header.getOrDefault("X-Amz-Signature")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Signature", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Content-Sha256", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Date")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Date", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Credential")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Credential", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Security-Token")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Security-Token", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Algorithm")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Algorithm", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-SignedHeaders", valid_606862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606864: Call_UpdateIntegration_606851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_606864.validator(path, query, header, formData, body)
  let scheme = call_606864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606864.url(scheme.get, call_606864.host, call_606864.base,
                         call_606864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606864, url, valid)

proc call*(call_606865: Call_UpdateIntegration_606851; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_606866 = newJObject()
  var body_606867 = newJObject()
  add(path_606866, "apiId", newJString(apiId))
  add(path_606866, "integrationId", newJString(integrationId))
  if body != nil:
    body_606867 = body
  result = call_606865.call(path_606866, nil, nil, nil, body_606867)

var updateIntegration* = Call_UpdateIntegration_606851(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_606852, base: "/",
    url: url_UpdateIntegration_606853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_606836 = ref object of OpenApiRestCall_605589
proc url_DeleteIntegration_606838(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_606837(path: JsonNode; query: JsonNode;
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
  var valid_606839 = path.getOrDefault("apiId")
  valid_606839 = validateParameter(valid_606839, JString, required = true,
                                 default = nil)
  if valid_606839 != nil:
    section.add "apiId", valid_606839
  var valid_606840 = path.getOrDefault("integrationId")
  valid_606840 = validateParameter(valid_606840, JString, required = true,
                                 default = nil)
  if valid_606840 != nil:
    section.add "integrationId", valid_606840
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
  var valid_606841 = header.getOrDefault("X-Amz-Signature")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Signature", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Content-Sha256", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Date")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Date", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Credential")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Credential", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Security-Token")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Security-Token", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Algorithm")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Algorithm", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-SignedHeaders", valid_606847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606848: Call_DeleteIntegration_606836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_606848.validator(path, query, header, formData, body)
  let scheme = call_606848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606848.url(scheme.get, call_606848.host, call_606848.base,
                         call_606848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606848, url, valid)

proc call*(call_606849: Call_DeleteIntegration_606836; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_606850 = newJObject()
  add(path_606850, "apiId", newJString(apiId))
  add(path_606850, "integrationId", newJString(integrationId))
  result = call_606849.call(path_606850, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_606836(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_606837, base: "/",
    url: url_DeleteIntegration_606838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_606868 = ref object of OpenApiRestCall_605589
proc url_GetIntegrationResponse_606870(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_606869(path: JsonNode; query: JsonNode;
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
  var valid_606871 = path.getOrDefault("integrationResponseId")
  valid_606871 = validateParameter(valid_606871, JString, required = true,
                                 default = nil)
  if valid_606871 != nil:
    section.add "integrationResponseId", valid_606871
  var valid_606872 = path.getOrDefault("apiId")
  valid_606872 = validateParameter(valid_606872, JString, required = true,
                                 default = nil)
  if valid_606872 != nil:
    section.add "apiId", valid_606872
  var valid_606873 = path.getOrDefault("integrationId")
  valid_606873 = validateParameter(valid_606873, JString, required = true,
                                 default = nil)
  if valid_606873 != nil:
    section.add "integrationId", valid_606873
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
  var valid_606874 = header.getOrDefault("X-Amz-Signature")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Signature", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Content-Sha256", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Date")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Date", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Credential")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Credential", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Security-Token")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Security-Token", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Algorithm")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Algorithm", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-SignedHeaders", valid_606880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606881: Call_GetIntegrationResponse_606868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_606881.validator(path, query, header, formData, body)
  let scheme = call_606881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606881.url(scheme.get, call_606881.host, call_606881.base,
                         call_606881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606881, url, valid)

proc call*(call_606882: Call_GetIntegrationResponse_606868;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_606883 = newJObject()
  add(path_606883, "integrationResponseId", newJString(integrationResponseId))
  add(path_606883, "apiId", newJString(apiId))
  add(path_606883, "integrationId", newJString(integrationId))
  result = call_606882.call(path_606883, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_606868(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_606869, base: "/",
    url: url_GetIntegrationResponse_606870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_606900 = ref object of OpenApiRestCall_605589
proc url_UpdateIntegrationResponse_606902(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_606901(path: JsonNode; query: JsonNode;
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
  var valid_606903 = path.getOrDefault("integrationResponseId")
  valid_606903 = validateParameter(valid_606903, JString, required = true,
                                 default = nil)
  if valid_606903 != nil:
    section.add "integrationResponseId", valid_606903
  var valid_606904 = path.getOrDefault("apiId")
  valid_606904 = validateParameter(valid_606904, JString, required = true,
                                 default = nil)
  if valid_606904 != nil:
    section.add "apiId", valid_606904
  var valid_606905 = path.getOrDefault("integrationId")
  valid_606905 = validateParameter(valid_606905, JString, required = true,
                                 default = nil)
  if valid_606905 != nil:
    section.add "integrationId", valid_606905
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
  var valid_606906 = header.getOrDefault("X-Amz-Signature")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Signature", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Content-Sha256", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Date")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Date", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Credential")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Credential", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Security-Token")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Security-Token", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-Algorithm")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Algorithm", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-SignedHeaders", valid_606912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606914: Call_UpdateIntegrationResponse_606900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_606914.validator(path, query, header, formData, body)
  let scheme = call_606914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606914.url(scheme.get, call_606914.host, call_606914.base,
                         call_606914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606914, url, valid)

proc call*(call_606915: Call_UpdateIntegrationResponse_606900;
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
  var path_606916 = newJObject()
  var body_606917 = newJObject()
  add(path_606916, "integrationResponseId", newJString(integrationResponseId))
  add(path_606916, "apiId", newJString(apiId))
  add(path_606916, "integrationId", newJString(integrationId))
  if body != nil:
    body_606917 = body
  result = call_606915.call(path_606916, nil, nil, nil, body_606917)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_606900(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_606901, base: "/",
    url: url_UpdateIntegrationResponse_606902,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_606884 = ref object of OpenApiRestCall_605589
proc url_DeleteIntegrationResponse_606886(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_606885(path: JsonNode; query: JsonNode;
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
  var valid_606887 = path.getOrDefault("integrationResponseId")
  valid_606887 = validateParameter(valid_606887, JString, required = true,
                                 default = nil)
  if valid_606887 != nil:
    section.add "integrationResponseId", valid_606887
  var valid_606888 = path.getOrDefault("apiId")
  valid_606888 = validateParameter(valid_606888, JString, required = true,
                                 default = nil)
  if valid_606888 != nil:
    section.add "apiId", valid_606888
  var valid_606889 = path.getOrDefault("integrationId")
  valid_606889 = validateParameter(valid_606889, JString, required = true,
                                 default = nil)
  if valid_606889 != nil:
    section.add "integrationId", valid_606889
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
  var valid_606890 = header.getOrDefault("X-Amz-Signature")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Signature", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Content-Sha256", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Date")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Date", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Credential")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Credential", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Security-Token")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Security-Token", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-Algorithm")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Algorithm", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-SignedHeaders", valid_606896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606897: Call_DeleteIntegrationResponse_606884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_606897.validator(path, query, header, formData, body)
  let scheme = call_606897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606897.url(scheme.get, call_606897.host, call_606897.base,
                         call_606897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606897, url, valid)

proc call*(call_606898: Call_DeleteIntegrationResponse_606884;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_606899 = newJObject()
  add(path_606899, "integrationResponseId", newJString(integrationResponseId))
  add(path_606899, "apiId", newJString(apiId))
  add(path_606899, "integrationId", newJString(integrationId))
  result = call_606898.call(path_606899, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_606884(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_606885, base: "/",
    url: url_DeleteIntegrationResponse_606886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_606918 = ref object of OpenApiRestCall_605589
proc url_GetModel_606920(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_606919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606921 = path.getOrDefault("apiId")
  valid_606921 = validateParameter(valid_606921, JString, required = true,
                                 default = nil)
  if valid_606921 != nil:
    section.add "apiId", valid_606921
  var valid_606922 = path.getOrDefault("modelId")
  valid_606922 = validateParameter(valid_606922, JString, required = true,
                                 default = nil)
  if valid_606922 != nil:
    section.add "modelId", valid_606922
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
  var valid_606923 = header.getOrDefault("X-Amz-Signature")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Signature", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Content-Sha256", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Date")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Date", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Credential")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Credential", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-Security-Token")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Security-Token", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Algorithm")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Algorithm", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-SignedHeaders", valid_606929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606930: Call_GetModel_606918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_606930.validator(path, query, header, formData, body)
  let scheme = call_606930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606930.url(scheme.get, call_606930.host, call_606930.base,
                         call_606930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606930, url, valid)

proc call*(call_606931: Call_GetModel_606918; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_606932 = newJObject()
  add(path_606932, "apiId", newJString(apiId))
  add(path_606932, "modelId", newJString(modelId))
  result = call_606931.call(path_606932, nil, nil, nil, nil)

var getModel* = Call_GetModel_606918(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_606919, base: "/",
                                  url: url_GetModel_606920,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_606948 = ref object of OpenApiRestCall_605589
proc url_UpdateModel_606950(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_606949(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606951 = path.getOrDefault("apiId")
  valid_606951 = validateParameter(valid_606951, JString, required = true,
                                 default = nil)
  if valid_606951 != nil:
    section.add "apiId", valid_606951
  var valid_606952 = path.getOrDefault("modelId")
  valid_606952 = validateParameter(valid_606952, JString, required = true,
                                 default = nil)
  if valid_606952 != nil:
    section.add "modelId", valid_606952
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
  var valid_606953 = header.getOrDefault("X-Amz-Signature")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Signature", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Content-Sha256", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Date")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Date", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Credential")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Credential", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Security-Token")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Security-Token", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Algorithm")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Algorithm", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-SignedHeaders", valid_606959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606961: Call_UpdateModel_606948; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_606961.validator(path, query, header, formData, body)
  let scheme = call_606961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606961.url(scheme.get, call_606961.host, call_606961.base,
                         call_606961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606961, url, valid)

proc call*(call_606962: Call_UpdateModel_606948; apiId: string; body: JsonNode;
          modelId: string): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   modelId: string (required)
  ##          : The model ID.
  var path_606963 = newJObject()
  var body_606964 = newJObject()
  add(path_606963, "apiId", newJString(apiId))
  if body != nil:
    body_606964 = body
  add(path_606963, "modelId", newJString(modelId))
  result = call_606962.call(path_606963, nil, nil, nil, body_606964)

var updateModel* = Call_UpdateModel_606948(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_606949,
                                        base: "/", url: url_UpdateModel_606950,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_606933 = ref object of OpenApiRestCall_605589
proc url_DeleteModel_606935(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_606934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606936 = path.getOrDefault("apiId")
  valid_606936 = validateParameter(valid_606936, JString, required = true,
                                 default = nil)
  if valid_606936 != nil:
    section.add "apiId", valid_606936
  var valid_606937 = path.getOrDefault("modelId")
  valid_606937 = validateParameter(valid_606937, JString, required = true,
                                 default = nil)
  if valid_606937 != nil:
    section.add "modelId", valid_606937
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
  var valid_606938 = header.getOrDefault("X-Amz-Signature")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Signature", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Content-Sha256", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Date")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Date", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Credential")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Credential", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-Security-Token")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Security-Token", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-Algorithm")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Algorithm", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-SignedHeaders", valid_606944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606945: Call_DeleteModel_606933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_606945.validator(path, query, header, formData, body)
  let scheme = call_606945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606945.url(scheme.get, call_606945.host, call_606945.base,
                         call_606945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606945, url, valid)

proc call*(call_606946: Call_DeleteModel_606933; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_606947 = newJObject()
  add(path_606947, "apiId", newJString(apiId))
  add(path_606947, "modelId", newJString(modelId))
  result = call_606946.call(path_606947, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_606933(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_606934,
                                        base: "/", url: url_DeleteModel_606935,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_606965 = ref object of OpenApiRestCall_605589
proc url_GetRoute_606967(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoute_606966(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606968 = path.getOrDefault("apiId")
  valid_606968 = validateParameter(valid_606968, JString, required = true,
                                 default = nil)
  if valid_606968 != nil:
    section.add "apiId", valid_606968
  var valid_606969 = path.getOrDefault("routeId")
  valid_606969 = validateParameter(valid_606969, JString, required = true,
                                 default = nil)
  if valid_606969 != nil:
    section.add "routeId", valid_606969
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
  var valid_606970 = header.getOrDefault("X-Amz-Signature")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Signature", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-Content-Sha256", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Date")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Date", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Credential")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Credential", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Security-Token")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Security-Token", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-Algorithm")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Algorithm", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-SignedHeaders", valid_606976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606977: Call_GetRoute_606965; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_606977.validator(path, query, header, formData, body)
  let scheme = call_606977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606977.url(scheme.get, call_606977.host, call_606977.base,
                         call_606977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606977, url, valid)

proc call*(call_606978: Call_GetRoute_606965; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_606979 = newJObject()
  add(path_606979, "apiId", newJString(apiId))
  add(path_606979, "routeId", newJString(routeId))
  result = call_606978.call(path_606979, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_606965(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_606966, base: "/",
                                  url: url_GetRoute_606967,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_606995 = ref object of OpenApiRestCall_605589
proc url_UpdateRoute_606997(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_606996(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606998 = path.getOrDefault("apiId")
  valid_606998 = validateParameter(valid_606998, JString, required = true,
                                 default = nil)
  if valid_606998 != nil:
    section.add "apiId", valid_606998
  var valid_606999 = path.getOrDefault("routeId")
  valid_606999 = validateParameter(valid_606999, JString, required = true,
                                 default = nil)
  if valid_606999 != nil:
    section.add "routeId", valid_606999
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
  var valid_607000 = header.getOrDefault("X-Amz-Signature")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Signature", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-Content-Sha256", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-Date")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-Date", valid_607002
  var valid_607003 = header.getOrDefault("X-Amz-Credential")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-Credential", valid_607003
  var valid_607004 = header.getOrDefault("X-Amz-Security-Token")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "X-Amz-Security-Token", valid_607004
  var valid_607005 = header.getOrDefault("X-Amz-Algorithm")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "X-Amz-Algorithm", valid_607005
  var valid_607006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-SignedHeaders", valid_607006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607008: Call_UpdateRoute_606995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_607008.validator(path, query, header, formData, body)
  let scheme = call_607008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607008.url(scheme.get, call_607008.host, call_607008.base,
                         call_607008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607008, url, valid)

proc call*(call_607009: Call_UpdateRoute_606995; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_607010 = newJObject()
  var body_607011 = newJObject()
  add(path_607010, "apiId", newJString(apiId))
  if body != nil:
    body_607011 = body
  add(path_607010, "routeId", newJString(routeId))
  result = call_607009.call(path_607010, nil, nil, nil, body_607011)

var updateRoute* = Call_UpdateRoute_606995(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_606996,
                                        base: "/", url: url_UpdateRoute_606997,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_606980 = ref object of OpenApiRestCall_605589
proc url_DeleteRoute_606982(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_606981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606983 = path.getOrDefault("apiId")
  valid_606983 = validateParameter(valid_606983, JString, required = true,
                                 default = nil)
  if valid_606983 != nil:
    section.add "apiId", valid_606983
  var valid_606984 = path.getOrDefault("routeId")
  valid_606984 = validateParameter(valid_606984, JString, required = true,
                                 default = nil)
  if valid_606984 != nil:
    section.add "routeId", valid_606984
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
  var valid_606985 = header.getOrDefault("X-Amz-Signature")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Signature", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Content-Sha256", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Date")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Date", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Credential")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Credential", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-Security-Token")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Security-Token", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Algorithm")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Algorithm", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-SignedHeaders", valid_606991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606992: Call_DeleteRoute_606980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_606992.validator(path, query, header, formData, body)
  let scheme = call_606992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606992.url(scheme.get, call_606992.host, call_606992.base,
                         call_606992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606992, url, valid)

proc call*(call_606993: Call_DeleteRoute_606980; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_606994 = newJObject()
  add(path_606994, "apiId", newJString(apiId))
  add(path_606994, "routeId", newJString(routeId))
  result = call_606993.call(path_606994, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_606980(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_606981,
                                        base: "/", url: url_DeleteRoute_606982,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_607012 = ref object of OpenApiRestCall_605589
proc url_GetRouteResponse_607014(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponse_607013(path: JsonNode; query: JsonNode;
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
  var valid_607015 = path.getOrDefault("apiId")
  valid_607015 = validateParameter(valid_607015, JString, required = true,
                                 default = nil)
  if valid_607015 != nil:
    section.add "apiId", valid_607015
  var valid_607016 = path.getOrDefault("routeResponseId")
  valid_607016 = validateParameter(valid_607016, JString, required = true,
                                 default = nil)
  if valid_607016 != nil:
    section.add "routeResponseId", valid_607016
  var valid_607017 = path.getOrDefault("routeId")
  valid_607017 = validateParameter(valid_607017, JString, required = true,
                                 default = nil)
  if valid_607017 != nil:
    section.add "routeId", valid_607017
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
  var valid_607018 = header.getOrDefault("X-Amz-Signature")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "X-Amz-Signature", valid_607018
  var valid_607019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Content-Sha256", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Date")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Date", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Credential")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Credential", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Security-Token")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Security-Token", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Algorithm")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Algorithm", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-SignedHeaders", valid_607024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607025: Call_GetRouteResponse_607012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_607025.validator(path, query, header, formData, body)
  let scheme = call_607025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607025.url(scheme.get, call_607025.host, call_607025.base,
                         call_607025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607025, url, valid)

proc call*(call_607026: Call_GetRouteResponse_607012; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_607027 = newJObject()
  add(path_607027, "apiId", newJString(apiId))
  add(path_607027, "routeResponseId", newJString(routeResponseId))
  add(path_607027, "routeId", newJString(routeId))
  result = call_607026.call(path_607027, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_607012(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_607013, base: "/",
    url: url_GetRouteResponse_607014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_607044 = ref object of OpenApiRestCall_605589
proc url_UpdateRouteResponse_607046(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRouteResponse_607045(path: JsonNode; query: JsonNode;
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
  var valid_607047 = path.getOrDefault("apiId")
  valid_607047 = validateParameter(valid_607047, JString, required = true,
                                 default = nil)
  if valid_607047 != nil:
    section.add "apiId", valid_607047
  var valid_607048 = path.getOrDefault("routeResponseId")
  valid_607048 = validateParameter(valid_607048, JString, required = true,
                                 default = nil)
  if valid_607048 != nil:
    section.add "routeResponseId", valid_607048
  var valid_607049 = path.getOrDefault("routeId")
  valid_607049 = validateParameter(valid_607049, JString, required = true,
                                 default = nil)
  if valid_607049 != nil:
    section.add "routeId", valid_607049
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
  var valid_607050 = header.getOrDefault("X-Amz-Signature")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-Signature", valid_607050
  var valid_607051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "X-Amz-Content-Sha256", valid_607051
  var valid_607052 = header.getOrDefault("X-Amz-Date")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "X-Amz-Date", valid_607052
  var valid_607053 = header.getOrDefault("X-Amz-Credential")
  valid_607053 = validateParameter(valid_607053, JString, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "X-Amz-Credential", valid_607053
  var valid_607054 = header.getOrDefault("X-Amz-Security-Token")
  valid_607054 = validateParameter(valid_607054, JString, required = false,
                                 default = nil)
  if valid_607054 != nil:
    section.add "X-Amz-Security-Token", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-Algorithm")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Algorithm", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-SignedHeaders", valid_607056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607058: Call_UpdateRouteResponse_607044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_607058.validator(path, query, header, formData, body)
  let scheme = call_607058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607058.url(scheme.get, call_607058.host, call_607058.base,
                         call_607058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607058, url, valid)

proc call*(call_607059: Call_UpdateRouteResponse_607044; apiId: string;
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
  var path_607060 = newJObject()
  var body_607061 = newJObject()
  add(path_607060, "apiId", newJString(apiId))
  add(path_607060, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_607061 = body
  add(path_607060, "routeId", newJString(routeId))
  result = call_607059.call(path_607060, nil, nil, nil, body_607061)

var updateRouteResponse* = Call_UpdateRouteResponse_607044(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_607045, base: "/",
    url: url_UpdateRouteResponse_607046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_607028 = ref object of OpenApiRestCall_605589
proc url_DeleteRouteResponse_607030(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRouteResponse_607029(path: JsonNode; query: JsonNode;
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
  var valid_607031 = path.getOrDefault("apiId")
  valid_607031 = validateParameter(valid_607031, JString, required = true,
                                 default = nil)
  if valid_607031 != nil:
    section.add "apiId", valid_607031
  var valid_607032 = path.getOrDefault("routeResponseId")
  valid_607032 = validateParameter(valid_607032, JString, required = true,
                                 default = nil)
  if valid_607032 != nil:
    section.add "routeResponseId", valid_607032
  var valid_607033 = path.getOrDefault("routeId")
  valid_607033 = validateParameter(valid_607033, JString, required = true,
                                 default = nil)
  if valid_607033 != nil:
    section.add "routeId", valid_607033
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
  var valid_607034 = header.getOrDefault("X-Amz-Signature")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Signature", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Content-Sha256", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Date")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Date", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Credential")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Credential", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Security-Token")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Security-Token", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Algorithm")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Algorithm", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-SignedHeaders", valid_607040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607041: Call_DeleteRouteResponse_607028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_607041.validator(path, query, header, formData, body)
  let scheme = call_607041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607041.url(scheme.get, call_607041.host, call_607041.base,
                         call_607041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607041, url, valid)

proc call*(call_607042: Call_DeleteRouteResponse_607028; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_607043 = newJObject()
  add(path_607043, "apiId", newJString(apiId))
  add(path_607043, "routeResponseId", newJString(routeResponseId))
  add(path_607043, "routeId", newJString(routeId))
  result = call_607042.call(path_607043, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_607028(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_607029, base: "/",
    url: url_DeleteRouteResponse_607030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteSettings_607062 = ref object of OpenApiRestCall_605589
proc url_DeleteRouteSettings_607064(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRouteSettings_607063(path: JsonNode; query: JsonNode;
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
  var valid_607065 = path.getOrDefault("stageName")
  valid_607065 = validateParameter(valid_607065, JString, required = true,
                                 default = nil)
  if valid_607065 != nil:
    section.add "stageName", valid_607065
  var valid_607066 = path.getOrDefault("routeKey")
  valid_607066 = validateParameter(valid_607066, JString, required = true,
                                 default = nil)
  if valid_607066 != nil:
    section.add "routeKey", valid_607066
  var valid_607067 = path.getOrDefault("apiId")
  valid_607067 = validateParameter(valid_607067, JString, required = true,
                                 default = nil)
  if valid_607067 != nil:
    section.add "apiId", valid_607067
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
  var valid_607068 = header.getOrDefault("X-Amz-Signature")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Signature", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-Content-Sha256", valid_607069
  var valid_607070 = header.getOrDefault("X-Amz-Date")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-Date", valid_607070
  var valid_607071 = header.getOrDefault("X-Amz-Credential")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-Credential", valid_607071
  var valid_607072 = header.getOrDefault("X-Amz-Security-Token")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Security-Token", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Algorithm")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Algorithm", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-SignedHeaders", valid_607074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607075: Call_DeleteRouteSettings_607062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the RouteSettings for a stage.
  ## 
  let valid = call_607075.validator(path, query, header, formData, body)
  let scheme = call_607075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607075.url(scheme.get, call_607075.host, call_607075.base,
                         call_607075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607075, url, valid)

proc call*(call_607076: Call_DeleteRouteSettings_607062; stageName: string;
          routeKey: string; apiId: string): Recallable =
  ## deleteRouteSettings
  ## Deletes the RouteSettings for a stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   routeKey: string (required)
  ##           : The route key.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_607077 = newJObject()
  add(path_607077, "stageName", newJString(stageName))
  add(path_607077, "routeKey", newJString(routeKey))
  add(path_607077, "apiId", newJString(apiId))
  result = call_607076.call(path_607077, nil, nil, nil, nil)

var deleteRouteSettings* = Call_DeleteRouteSettings_607062(
    name: "deleteRouteSettings", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}",
    validator: validate_DeleteRouteSettings_607063, base: "/",
    url: url_DeleteRouteSettings_607064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_607078 = ref object of OpenApiRestCall_605589
proc url_GetStage_607080(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_607079(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607081 = path.getOrDefault("stageName")
  valid_607081 = validateParameter(valid_607081, JString, required = true,
                                 default = nil)
  if valid_607081 != nil:
    section.add "stageName", valid_607081
  var valid_607082 = path.getOrDefault("apiId")
  valid_607082 = validateParameter(valid_607082, JString, required = true,
                                 default = nil)
  if valid_607082 != nil:
    section.add "apiId", valid_607082
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
  var valid_607083 = header.getOrDefault("X-Amz-Signature")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-Signature", valid_607083
  var valid_607084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "X-Amz-Content-Sha256", valid_607084
  var valid_607085 = header.getOrDefault("X-Amz-Date")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Date", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-Credential")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-Credential", valid_607086
  var valid_607087 = header.getOrDefault("X-Amz-Security-Token")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-Security-Token", valid_607087
  var valid_607088 = header.getOrDefault("X-Amz-Algorithm")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "X-Amz-Algorithm", valid_607088
  var valid_607089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "X-Amz-SignedHeaders", valid_607089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607090: Call_GetStage_607078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_607090.validator(path, query, header, formData, body)
  let scheme = call_607090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607090.url(scheme.get, call_607090.host, call_607090.base,
                         call_607090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607090, url, valid)

proc call*(call_607091: Call_GetStage_607078; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_607092 = newJObject()
  add(path_607092, "stageName", newJString(stageName))
  add(path_607092, "apiId", newJString(apiId))
  result = call_607091.call(path_607092, nil, nil, nil, nil)

var getStage* = Call_GetStage_607078(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_607079, base: "/",
                                  url: url_GetStage_607080,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_607108 = ref object of OpenApiRestCall_605589
proc url_UpdateStage_607110(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_607109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607111 = path.getOrDefault("stageName")
  valid_607111 = validateParameter(valid_607111, JString, required = true,
                                 default = nil)
  if valid_607111 != nil:
    section.add "stageName", valid_607111
  var valid_607112 = path.getOrDefault("apiId")
  valid_607112 = validateParameter(valid_607112, JString, required = true,
                                 default = nil)
  if valid_607112 != nil:
    section.add "apiId", valid_607112
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
  var valid_607113 = header.getOrDefault("X-Amz-Signature")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Signature", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Content-Sha256", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-Date")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-Date", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-Credential")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Credential", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-Security-Token")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-Security-Token", valid_607117
  var valid_607118 = header.getOrDefault("X-Amz-Algorithm")
  valid_607118 = validateParameter(valid_607118, JString, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "X-Amz-Algorithm", valid_607118
  var valid_607119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607119 = validateParameter(valid_607119, JString, required = false,
                                 default = nil)
  if valid_607119 != nil:
    section.add "X-Amz-SignedHeaders", valid_607119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607121: Call_UpdateStage_607108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_607121.validator(path, query, header, formData, body)
  let scheme = call_607121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607121.url(scheme.get, call_607121.host, call_607121.base,
                         call_607121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607121, url, valid)

proc call*(call_607122: Call_UpdateStage_607108; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_607123 = newJObject()
  var body_607124 = newJObject()
  add(path_607123, "stageName", newJString(stageName))
  add(path_607123, "apiId", newJString(apiId))
  if body != nil:
    body_607124 = body
  result = call_607122.call(path_607123, nil, nil, nil, body_607124)

var updateStage* = Call_UpdateStage_607108(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_607109,
                                        base: "/", url: url_UpdateStage_607110,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_607093 = ref object of OpenApiRestCall_605589
proc url_DeleteStage_607095(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_607094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607096 = path.getOrDefault("stageName")
  valid_607096 = validateParameter(valid_607096, JString, required = true,
                                 default = nil)
  if valid_607096 != nil:
    section.add "stageName", valid_607096
  var valid_607097 = path.getOrDefault("apiId")
  valid_607097 = validateParameter(valid_607097, JString, required = true,
                                 default = nil)
  if valid_607097 != nil:
    section.add "apiId", valid_607097
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
  var valid_607098 = header.getOrDefault("X-Amz-Signature")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Signature", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-Content-Sha256", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-Date")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-Date", valid_607100
  var valid_607101 = header.getOrDefault("X-Amz-Credential")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "X-Amz-Credential", valid_607101
  var valid_607102 = header.getOrDefault("X-Amz-Security-Token")
  valid_607102 = validateParameter(valid_607102, JString, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "X-Amz-Security-Token", valid_607102
  var valid_607103 = header.getOrDefault("X-Amz-Algorithm")
  valid_607103 = validateParameter(valid_607103, JString, required = false,
                                 default = nil)
  if valid_607103 != nil:
    section.add "X-Amz-Algorithm", valid_607103
  var valid_607104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607104 = validateParameter(valid_607104, JString, required = false,
                                 default = nil)
  if valid_607104 != nil:
    section.add "X-Amz-SignedHeaders", valid_607104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607105: Call_DeleteStage_607093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_607105.validator(path, query, header, formData, body)
  let scheme = call_607105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607105.url(scheme.get, call_607105.host, call_607105.base,
                         call_607105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607105, url, valid)

proc call*(call_607106: Call_DeleteStage_607093; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_607107 = newJObject()
  add(path_607107, "stageName", newJString(stageName))
  add(path_607107, "apiId", newJString(apiId))
  result = call_607106.call(path_607107, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_607093(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_607094,
                                        base: "/", url: url_DeleteStage_607095,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_607125 = ref object of OpenApiRestCall_605589
proc url_GetModelTemplate_607127(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_607126(path: JsonNode; query: JsonNode;
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
  var valid_607128 = path.getOrDefault("apiId")
  valid_607128 = validateParameter(valid_607128, JString, required = true,
                                 default = nil)
  if valid_607128 != nil:
    section.add "apiId", valid_607128
  var valid_607129 = path.getOrDefault("modelId")
  valid_607129 = validateParameter(valid_607129, JString, required = true,
                                 default = nil)
  if valid_607129 != nil:
    section.add "modelId", valid_607129
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
  var valid_607130 = header.getOrDefault("X-Amz-Signature")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Signature", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Content-Sha256", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Date")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Date", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-Credential")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-Credential", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-Security-Token")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-Security-Token", valid_607134
  var valid_607135 = header.getOrDefault("X-Amz-Algorithm")
  valid_607135 = validateParameter(valid_607135, JString, required = false,
                                 default = nil)
  if valid_607135 != nil:
    section.add "X-Amz-Algorithm", valid_607135
  var valid_607136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "X-Amz-SignedHeaders", valid_607136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607137: Call_GetModelTemplate_607125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_607137.validator(path, query, header, formData, body)
  let scheme = call_607137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607137.url(scheme.get, call_607137.host, call_607137.base,
                         call_607137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607137, url, valid)

proc call*(call_607138: Call_GetModelTemplate_607125; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_607139 = newJObject()
  add(path_607139, "apiId", newJString(apiId))
  add(path_607139, "modelId", newJString(modelId))
  result = call_607138.call(path_607139, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_607125(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_607126, base: "/",
    url: url_GetModelTemplate_607127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607154 = ref object of OpenApiRestCall_605589
proc url_TagResource_607156(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607157 = path.getOrDefault("resource-arn")
  valid_607157 = validateParameter(valid_607157, JString, required = true,
                                 default = nil)
  if valid_607157 != nil:
    section.add "resource-arn", valid_607157
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
  var valid_607158 = header.getOrDefault("X-Amz-Signature")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Signature", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-Content-Sha256", valid_607159
  var valid_607160 = header.getOrDefault("X-Amz-Date")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Date", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Credential")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Credential", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Security-Token")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Security-Token", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-Algorithm")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-Algorithm", valid_607163
  var valid_607164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-SignedHeaders", valid_607164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607166: Call_TagResource_607154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Tag resource to represent a tag.
  ## 
  let valid = call_607166.validator(path, query, header, formData, body)
  let scheme = call_607166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607166.url(scheme.get, call_607166.host, call_607166.base,
                         call_607166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607166, url, valid)

proc call*(call_607167: Call_TagResource_607154; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a new Tag resource to represent a tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   body: JObject (required)
  var path_607168 = newJObject()
  var body_607169 = newJObject()
  add(path_607168, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_607169 = body
  result = call_607167.call(path_607168, nil, nil, nil, body_607169)

var tagResource* = Call_TagResource_607154(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_607155,
                                        base: "/", url: url_TagResource_607156,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_607140 = ref object of OpenApiRestCall_605589
proc url_GetTags_607142(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_607141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607143 = path.getOrDefault("resource-arn")
  valid_607143 = validateParameter(valid_607143, JString, required = true,
                                 default = nil)
  if valid_607143 != nil:
    section.add "resource-arn", valid_607143
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
  var valid_607144 = header.getOrDefault("X-Amz-Signature")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Signature", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Content-Sha256", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Date")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Date", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Credential")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Credential", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-Security-Token")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-Security-Token", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-Algorithm")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Algorithm", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-SignedHeaders", valid_607150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607151: Call_GetTags_607140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Tag resources.
  ## 
  let valid = call_607151.validator(path, query, header, formData, body)
  let scheme = call_607151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607151.url(scheme.get, call_607151.host, call_607151.base,
                         call_607151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607151, url, valid)

proc call*(call_607152: Call_GetTags_607140; resourceArn: string): Recallable =
  ## getTags
  ## Gets a collection of Tag resources.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  var path_607153 = newJObject()
  add(path_607153, "resource-arn", newJString(resourceArn))
  result = call_607152.call(path_607153, nil, nil, nil, nil)

var getTags* = Call_GetTags_607140(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_607141, base: "/",
                                url: url_GetTags_607142,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607170 = ref object of OpenApiRestCall_605589
proc url_UntagResource_607172(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607171(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607173 = path.getOrDefault("resource-arn")
  valid_607173 = validateParameter(valid_607173, JString, required = true,
                                 default = nil)
  if valid_607173 != nil:
    section.add "resource-arn", valid_607173
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_607174 = query.getOrDefault("tagKeys")
  valid_607174 = validateParameter(valid_607174, JArray, required = true, default = nil)
  if valid_607174 != nil:
    section.add "tagKeys", valid_607174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607175 = header.getOrDefault("X-Amz-Signature")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Signature", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Content-Sha256", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Date")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Date", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-Credential")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-Credential", valid_607178
  var valid_607179 = header.getOrDefault("X-Amz-Security-Token")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "X-Amz-Security-Token", valid_607179
  var valid_607180 = header.getOrDefault("X-Amz-Algorithm")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "X-Amz-Algorithm", valid_607180
  var valid_607181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "X-Amz-SignedHeaders", valid_607181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607182: Call_UntagResource_607170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Tag.
  ## 
  let valid = call_607182.validator(path, query, header, formData, body)
  let scheme = call_607182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607182.url(scheme.get, call_607182.host, call_607182.base,
                         call_607182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607182, url, valid)

proc call*(call_607183: Call_UntagResource_607170; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a Tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  var path_607184 = newJObject()
  var query_607185 = newJObject()
  add(path_607184, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_607185.add "tagKeys", tagKeys
  result = call_607183.call(path_607184, query_607185, nil, nil, nil)

var untagResource* = Call_UntagResource_607170(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_607171,
    base: "/", url: url_UntagResource_607172, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
