
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon API Gateway
## version: 2015-07-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon API Gateway</fullname> <p>Amazon API Gateway helps developers deliver robust, secure, and scalable mobile and web application back ends. API Gateway allows developers to securely connect mobile and web applications to APIs that run on AWS Lambda, Amazon EC2, or other publicly addressable web services that are hosted outside of AWS.</p>
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  awsServiceName = "apigateway"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_613240 = ref object of OpenApiRestCall_612642
proc url_CreateApiKey_613242(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiKey_613241(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
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
  var valid_613243 = header.getOrDefault("X-Amz-Signature")
  valid_613243 = validateParameter(valid_613243, JString, required = false,
                                 default = nil)
  if valid_613243 != nil:
    section.add "X-Amz-Signature", valid_613243
  var valid_613244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613244 = validateParameter(valid_613244, JString, required = false,
                                 default = nil)
  if valid_613244 != nil:
    section.add "X-Amz-Content-Sha256", valid_613244
  var valid_613245 = header.getOrDefault("X-Amz-Date")
  valid_613245 = validateParameter(valid_613245, JString, required = false,
                                 default = nil)
  if valid_613245 != nil:
    section.add "X-Amz-Date", valid_613245
  var valid_613246 = header.getOrDefault("X-Amz-Credential")
  valid_613246 = validateParameter(valid_613246, JString, required = false,
                                 default = nil)
  if valid_613246 != nil:
    section.add "X-Amz-Credential", valid_613246
  var valid_613247 = header.getOrDefault("X-Amz-Security-Token")
  valid_613247 = validateParameter(valid_613247, JString, required = false,
                                 default = nil)
  if valid_613247 != nil:
    section.add "X-Amz-Security-Token", valid_613247
  var valid_613248 = header.getOrDefault("X-Amz-Algorithm")
  valid_613248 = validateParameter(valid_613248, JString, required = false,
                                 default = nil)
  if valid_613248 != nil:
    section.add "X-Amz-Algorithm", valid_613248
  var valid_613249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613249 = validateParameter(valid_613249, JString, required = false,
                                 default = nil)
  if valid_613249 != nil:
    section.add "X-Amz-SignedHeaders", valid_613249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613251: Call_CreateApiKey_613240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_613251.validator(path, query, header, formData, body)
  let scheme = call_613251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613251.url(scheme.get, call_613251.host, call_613251.base,
                         call_613251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613251, url, valid)

proc call*(call_613252: Call_CreateApiKey_613240; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_613253 = newJObject()
  if body != nil:
    body_613253 = body
  result = call_613252.call(nil, nil, nil, nil, body_613253)

var createApiKey* = Call_CreateApiKey_613240(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_613241, base: "/", url: url_CreateApiKey_613242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_612980 = ref object of OpenApiRestCall_612642
proc url_GetApiKeys_612982(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKeys_612981(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : The name of queried API keys.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   includeValues: JBool
  ##                : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains key values.
  ##   customerId: JString
  ##             : The identifier of a customer in AWS Marketplace or an external system, such as a developer portal.
  section = newJObject()
  var valid_613094 = query.getOrDefault("name")
  valid_613094 = validateParameter(valid_613094, JString, required = false,
                                 default = nil)
  if valid_613094 != nil:
    section.add "name", valid_613094
  var valid_613095 = query.getOrDefault("limit")
  valid_613095 = validateParameter(valid_613095, JInt, required = false, default = nil)
  if valid_613095 != nil:
    section.add "limit", valid_613095
  var valid_613096 = query.getOrDefault("position")
  valid_613096 = validateParameter(valid_613096, JString, required = false,
                                 default = nil)
  if valid_613096 != nil:
    section.add "position", valid_613096
  var valid_613097 = query.getOrDefault("includeValues")
  valid_613097 = validateParameter(valid_613097, JBool, required = false, default = nil)
  if valid_613097 != nil:
    section.add "includeValues", valid_613097
  var valid_613098 = query.getOrDefault("customerId")
  valid_613098 = validateParameter(valid_613098, JString, required = false,
                                 default = nil)
  if valid_613098 != nil:
    section.add "customerId", valid_613098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613099 = header.getOrDefault("X-Amz-Signature")
  valid_613099 = validateParameter(valid_613099, JString, required = false,
                                 default = nil)
  if valid_613099 != nil:
    section.add "X-Amz-Signature", valid_613099
  var valid_613100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613100 = validateParameter(valid_613100, JString, required = false,
                                 default = nil)
  if valid_613100 != nil:
    section.add "X-Amz-Content-Sha256", valid_613100
  var valid_613101 = header.getOrDefault("X-Amz-Date")
  valid_613101 = validateParameter(valid_613101, JString, required = false,
                                 default = nil)
  if valid_613101 != nil:
    section.add "X-Amz-Date", valid_613101
  var valid_613102 = header.getOrDefault("X-Amz-Credential")
  valid_613102 = validateParameter(valid_613102, JString, required = false,
                                 default = nil)
  if valid_613102 != nil:
    section.add "X-Amz-Credential", valid_613102
  var valid_613103 = header.getOrDefault("X-Amz-Security-Token")
  valid_613103 = validateParameter(valid_613103, JString, required = false,
                                 default = nil)
  if valid_613103 != nil:
    section.add "X-Amz-Security-Token", valid_613103
  var valid_613104 = header.getOrDefault("X-Amz-Algorithm")
  valid_613104 = validateParameter(valid_613104, JString, required = false,
                                 default = nil)
  if valid_613104 != nil:
    section.add "X-Amz-Algorithm", valid_613104
  var valid_613105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613105 = validateParameter(valid_613105, JString, required = false,
                                 default = nil)
  if valid_613105 != nil:
    section.add "X-Amz-SignedHeaders", valid_613105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613128: Call_GetApiKeys_612980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_613128.validator(path, query, header, formData, body)
  let scheme = call_613128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613128.url(scheme.get, call_613128.host, call_613128.base,
                         call_613128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613128, url, valid)

proc call*(call_613199: Call_GetApiKeys_612980; name: string = ""; limit: int = 0;
          position: string = ""; includeValues: bool = false; customerId: string = ""): Recallable =
  ## getApiKeys
  ## Gets information about the current <a>ApiKeys</a> resource.
  ##   name: string
  ##       : The name of queried API keys.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   includeValues: bool
  ##                : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains key values.
  ##   customerId: string
  ##             : The identifier of a customer in AWS Marketplace or an external system, such as a developer portal.
  var query_613200 = newJObject()
  add(query_613200, "name", newJString(name))
  add(query_613200, "limit", newJInt(limit))
  add(query_613200, "position", newJString(position))
  add(query_613200, "includeValues", newJBool(includeValues))
  add(query_613200, "customerId", newJString(customerId))
  result = call_613199.call(nil, query_613200, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_612980(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_612981,
                                      base: "/", url: url_GetApiKeys_612982,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_613285 = ref object of OpenApiRestCall_612642
proc url_CreateAuthorizer_613287(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_CreateAuthorizer_613286(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613288 = path.getOrDefault("restapi_id")
  valid_613288 = validateParameter(valid_613288, JString, required = true,
                                 default = nil)
  if valid_613288 != nil:
    section.add "restapi_id", valid_613288
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
  var valid_613289 = header.getOrDefault("X-Amz-Signature")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Signature", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Content-Sha256", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Date")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Date", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Credential")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Credential", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Security-Token")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Security-Token", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Algorithm")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Algorithm", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-SignedHeaders", valid_613295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613297: Call_CreateAuthorizer_613285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_613297.validator(path, query, header, formData, body)
  let scheme = call_613297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613297.url(scheme.get, call_613297.host, call_613297.base,
                         call_613297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613297, url, valid)

proc call*(call_613298: Call_CreateAuthorizer_613285; restapiId: string;
          body: JsonNode): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613299 = newJObject()
  var body_613300 = newJObject()
  add(path_613299, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613300 = body
  result = call_613298.call(path_613299, nil, nil, nil, body_613300)

var createAuthorizer* = Call_CreateAuthorizer_613285(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_613286, base: "/",
    url: url_CreateAuthorizer_613287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_613254 = ref object of OpenApiRestCall_612642
proc url_GetAuthorizers_613256(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_GetAuthorizers_613255(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613271 = path.getOrDefault("restapi_id")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "restapi_id", valid_613271
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613272 = query.getOrDefault("limit")
  valid_613272 = validateParameter(valid_613272, JInt, required = false, default = nil)
  if valid_613272 != nil:
    section.add "limit", valid_613272
  var valid_613273 = query.getOrDefault("position")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "position", valid_613273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613274 = header.getOrDefault("X-Amz-Signature")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Signature", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Content-Sha256", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Date")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Date", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Credential")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Credential", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Security-Token")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Security-Token", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Algorithm")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Algorithm", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-SignedHeaders", valid_613280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613281: Call_GetAuthorizers_613254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_613281.validator(path, query, header, formData, body)
  let scheme = call_613281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613281.url(scheme.get, call_613281.host, call_613281.base,
                         call_613281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613281, url, valid)

proc call*(call_613282: Call_GetAuthorizers_613254; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613283 = newJObject()
  var query_613284 = newJObject()
  add(query_613284, "limit", newJInt(limit))
  add(query_613284, "position", newJString(position))
  add(path_613283, "restapi_id", newJString(restapiId))
  result = call_613282.call(path_613283, query_613284, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_613254(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_613255, base: "/", url: url_GetAuthorizers_613256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_613318 = ref object of OpenApiRestCall_612642
proc url_CreateBasePathMapping_613320(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name"),
               (kind: ConstantSegment, value: "/basepathmappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBasePathMapping_613319(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domain_name: JString (required)
  ##              : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domain_name` field"
  var valid_613321 = path.getOrDefault("domain_name")
  valid_613321 = validateParameter(valid_613321, JString, required = true,
                                 default = nil)
  if valid_613321 != nil:
    section.add "domain_name", valid_613321
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
  var valid_613322 = header.getOrDefault("X-Amz-Signature")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Signature", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Content-Sha256", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Date")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Date", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Credential")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Credential", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Security-Token")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Security-Token", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Algorithm")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Algorithm", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-SignedHeaders", valid_613328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613330: Call_CreateBasePathMapping_613318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_613330.validator(path, query, header, formData, body)
  let scheme = call_613330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613330.url(scheme.get, call_613330.host, call_613330.base,
                         call_613330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613330, url, valid)

proc call*(call_613331: Call_CreateBasePathMapping_613318; body: JsonNode;
          domainName: string): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  var path_613332 = newJObject()
  var body_613333 = newJObject()
  if body != nil:
    body_613333 = body
  add(path_613332, "domain_name", newJString(domainName))
  result = call_613331.call(path_613332, nil, nil, nil, body_613333)

var createBasePathMapping* = Call_CreateBasePathMapping_613318(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_613319, base: "/",
    url: url_CreateBasePathMapping_613320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_613301 = ref object of OpenApiRestCall_612642
proc url_GetBasePathMappings_613303(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name"),
               (kind: ConstantSegment, value: "/basepathmappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBasePathMappings_613302(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domain_name: JString (required)
  ##              : [Required] The domain name of a <a>BasePathMapping</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domain_name` field"
  var valid_613304 = path.getOrDefault("domain_name")
  valid_613304 = validateParameter(valid_613304, JString, required = true,
                                 default = nil)
  if valid_613304 != nil:
    section.add "domain_name", valid_613304
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613305 = query.getOrDefault("limit")
  valid_613305 = validateParameter(valid_613305, JInt, required = false, default = nil)
  if valid_613305 != nil:
    section.add "limit", valid_613305
  var valid_613306 = query.getOrDefault("position")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "position", valid_613306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613314: Call_GetBasePathMappings_613301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_613314.validator(path, query, header, formData, body)
  let scheme = call_613314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613314.url(scheme.get, call_613314.host, call_613314.base,
                         call_613314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613314, url, valid)

proc call*(call_613315: Call_GetBasePathMappings_613301; domainName: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  var path_613316 = newJObject()
  var query_613317 = newJObject()
  add(query_613317, "limit", newJInt(limit))
  add(query_613317, "position", newJString(position))
  add(path_613316, "domain_name", newJString(domainName))
  result = call_613315.call(path_613316, query_613317, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_613301(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_613302, base: "/",
    url: url_GetBasePathMappings_613303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_613351 = ref object of OpenApiRestCall_612642
proc url_CreateDeployment_613353(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_CreateDeployment_613352(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613354 = path.getOrDefault("restapi_id")
  valid_613354 = validateParameter(valid_613354, JString, required = true,
                                 default = nil)
  if valid_613354 != nil:
    section.add "restapi_id", valid_613354
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
  var valid_613355 = header.getOrDefault("X-Amz-Signature")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Signature", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Content-Sha256", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Date")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Date", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Credential")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Credential", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Security-Token")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Security-Token", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Algorithm")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Algorithm", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-SignedHeaders", valid_613361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613363: Call_CreateDeployment_613351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_613363.validator(path, query, header, formData, body)
  let scheme = call_613363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613363.url(scheme.get, call_613363.host, call_613363.base,
                         call_613363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613363, url, valid)

proc call*(call_613364: Call_CreateDeployment_613351; restapiId: string;
          body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613365 = newJObject()
  var body_613366 = newJObject()
  add(path_613365, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613366 = body
  result = call_613364.call(path_613365, nil, nil, nil, body_613366)

var createDeployment* = Call_CreateDeployment_613351(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_613352, base: "/",
    url: url_CreateDeployment_613353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_613334 = ref object of OpenApiRestCall_612642
proc url_GetDeployments_613336(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_GetDeployments_613335(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613337 = path.getOrDefault("restapi_id")
  valid_613337 = validateParameter(valid_613337, JString, required = true,
                                 default = nil)
  if valid_613337 != nil:
    section.add "restapi_id", valid_613337
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613338 = query.getOrDefault("limit")
  valid_613338 = validateParameter(valid_613338, JInt, required = false, default = nil)
  if valid_613338 != nil:
    section.add "limit", valid_613338
  var valid_613339 = query.getOrDefault("position")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "position", valid_613339
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613340 = header.getOrDefault("X-Amz-Signature")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Signature", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Content-Sha256", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Date")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Date", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Credential")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Credential", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Security-Token")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Security-Token", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Algorithm")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Algorithm", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-SignedHeaders", valid_613346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613347: Call_GetDeployments_613334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_613347.validator(path, query, header, formData, body)
  let scheme = call_613347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613347.url(scheme.get, call_613347.host, call_613347.base,
                         call_613347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613347, url, valid)

proc call*(call_613348: Call_GetDeployments_613334; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613349 = newJObject()
  var query_613350 = newJObject()
  add(query_613350, "limit", newJInt(limit))
  add(query_613350, "position", newJString(position))
  add(path_613349, "restapi_id", newJString(restapiId))
  result = call_613348.call(path_613349, query_613350, nil, nil, nil)

var getDeployments* = Call_GetDeployments_613334(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_613335, base: "/", url: url_GetDeployments_613336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_613401 = ref object of OpenApiRestCall_612642
proc url_ImportDocumentationParts_613403(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ImportDocumentationParts_613402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613404 = path.getOrDefault("restapi_id")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = nil)
  if valid_613404 != nil:
    section.add "restapi_id", valid_613404
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  section = newJObject()
  var valid_613405 = query.getOrDefault("failonwarnings")
  valid_613405 = validateParameter(valid_613405, JBool, required = false, default = nil)
  if valid_613405 != nil:
    section.add "failonwarnings", valid_613405
  var valid_613406 = query.getOrDefault("mode")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = newJString("merge"))
  if valid_613406 != nil:
    section.add "mode", valid_613406
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613407 = header.getOrDefault("X-Amz-Signature")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Signature", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Content-Sha256", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Date")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Date", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Credential")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Credential", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Security-Token")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Security-Token", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Algorithm")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Algorithm", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-SignedHeaders", valid_613413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613415: Call_ImportDocumentationParts_613401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613415.validator(path, query, header, formData, body)
  let scheme = call_613415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613415.url(scheme.get, call_613415.host, call_613415.base,
                         call_613415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613415, url, valid)

proc call*(call_613416: Call_ImportDocumentationParts_613401; restapiId: string;
          body: JsonNode; failonwarnings: bool = false; mode: string = "merge"): Recallable =
  ## importDocumentationParts
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613417 = newJObject()
  var query_613418 = newJObject()
  var body_613419 = newJObject()
  add(query_613418, "failonwarnings", newJBool(failonwarnings))
  add(query_613418, "mode", newJString(mode))
  add(path_613417, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613419 = body
  result = call_613416.call(path_613417, query_613418, nil, nil, body_613419)

var importDocumentationParts* = Call_ImportDocumentationParts_613401(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_613402, base: "/",
    url: url_ImportDocumentationParts_613403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_613420 = ref object of OpenApiRestCall_612642
proc url_CreateDocumentationPart_613422(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDocumentationPart_613421(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613423 = path.getOrDefault("restapi_id")
  valid_613423 = validateParameter(valid_613423, JString, required = true,
                                 default = nil)
  if valid_613423 != nil:
    section.add "restapi_id", valid_613423
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
  var valid_613424 = header.getOrDefault("X-Amz-Signature")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Signature", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Content-Sha256", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Date")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Date", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Credential")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Credential", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Security-Token")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Security-Token", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Algorithm")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Algorithm", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-SignedHeaders", valid_613430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613432: Call_CreateDocumentationPart_613420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613432.validator(path, query, header, formData, body)
  let scheme = call_613432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613432.url(scheme.get, call_613432.host, call_613432.base,
                         call_613432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613432, url, valid)

proc call*(call_613433: Call_CreateDocumentationPart_613420; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationPart
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613434 = newJObject()
  var body_613435 = newJObject()
  add(path_613434, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613435 = body
  result = call_613433.call(path_613434, nil, nil, nil, body_613435)

var createDocumentationPart* = Call_CreateDocumentationPart_613420(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_613421, base: "/",
    url: url_CreateDocumentationPart_613422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_613367 = ref object of OpenApiRestCall_612642
proc url_GetDocumentationParts_613369(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationParts_613368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613370 = path.getOrDefault("restapi_id")
  valid_613370 = validateParameter(valid_613370, JString, required = true,
                                 default = nil)
  if valid_613370 != nil:
    section.add "restapi_id", valid_613370
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : The name of API entities of the to-be-retrieved documentation parts.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   locationStatus: JString
  ##                 : The status of the API documentation parts to retrieve. Valid values are <code>DOCUMENTED</code> for retrieving <a>DocumentationPart</a> resources with content and <code>UNDOCUMENTED</code> for <a>DocumentationPart</a> resources without content.
  ##   path: JString
  ##       : The path of API entities of the to-be-retrieved documentation parts.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   type: JString
  ##       : The type of API entities of the to-be-retrieved documentation parts. 
  section = newJObject()
  var valid_613371 = query.getOrDefault("name")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "name", valid_613371
  var valid_613372 = query.getOrDefault("limit")
  valid_613372 = validateParameter(valid_613372, JInt, required = false, default = nil)
  if valid_613372 != nil:
    section.add "limit", valid_613372
  var valid_613386 = query.getOrDefault("locationStatus")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_613386 != nil:
    section.add "locationStatus", valid_613386
  var valid_613387 = query.getOrDefault("path")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "path", valid_613387
  var valid_613388 = query.getOrDefault("position")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "position", valid_613388
  var valid_613389 = query.getOrDefault("type")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = newJString("API"))
  if valid_613389 != nil:
    section.add "type", valid_613389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613390 = header.getOrDefault("X-Amz-Signature")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Signature", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Content-Sha256", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Date")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Date", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Credential")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Credential", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Security-Token")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Security-Token", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Algorithm")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Algorithm", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-SignedHeaders", valid_613396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_GetDocumentationParts_613367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_GetDocumentationParts_613367; restapiId: string;
          name: string = ""; limit: int = 0; locationStatus: string = "DOCUMENTED";
          path: string = ""; position: string = ""; `type`: string = "API"): Recallable =
  ## getDocumentationParts
  ##   name: string
  ##       : The name of API entities of the to-be-retrieved documentation parts.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   locationStatus: string
  ##                 : The status of the API documentation parts to retrieve. Valid values are <code>DOCUMENTED</code> for retrieving <a>DocumentationPart</a> resources with content and <code>UNDOCUMENTED</code> for <a>DocumentationPart</a> resources without content.
  ##   path: string
  ##       : The path of API entities of the to-be-retrieved documentation parts.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   type: string
  ##       : The type of API entities of the to-be-retrieved documentation parts. 
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613399 = newJObject()
  var query_613400 = newJObject()
  add(query_613400, "name", newJString(name))
  add(query_613400, "limit", newJInt(limit))
  add(query_613400, "locationStatus", newJString(locationStatus))
  add(query_613400, "path", newJString(path))
  add(query_613400, "position", newJString(position))
  add(query_613400, "type", newJString(`type`))
  add(path_613399, "restapi_id", newJString(restapiId))
  result = call_613398.call(path_613399, query_613400, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_613367(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_613368, base: "/",
    url: url_GetDocumentationParts_613369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_613453 = ref object of OpenApiRestCall_612642
proc url_CreateDocumentationVersion_613455(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDocumentationVersion_613454(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613456 = path.getOrDefault("restapi_id")
  valid_613456 = validateParameter(valid_613456, JString, required = true,
                                 default = nil)
  if valid_613456 != nil:
    section.add "restapi_id", valid_613456
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
  var valid_613457 = header.getOrDefault("X-Amz-Signature")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Signature", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Content-Sha256", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Date")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Date", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Credential")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Credential", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Security-Token")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Security-Token", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Algorithm")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Algorithm", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-SignedHeaders", valid_613463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613465: Call_CreateDocumentationVersion_613453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613465.validator(path, query, header, formData, body)
  let scheme = call_613465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613465.url(scheme.get, call_613465.host, call_613465.base,
                         call_613465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613465, url, valid)

proc call*(call_613466: Call_CreateDocumentationVersion_613453; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationVersion
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613467 = newJObject()
  var body_613468 = newJObject()
  add(path_613467, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613468 = body
  result = call_613466.call(path_613467, nil, nil, nil, body_613468)

var createDocumentationVersion* = Call_CreateDocumentationVersion_613453(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_613454, base: "/",
    url: url_CreateDocumentationVersion_613455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_613436 = ref object of OpenApiRestCall_612642
proc url_GetDocumentationVersions_613438(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationVersions_613437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613439 = path.getOrDefault("restapi_id")
  valid_613439 = validateParameter(valid_613439, JString, required = true,
                                 default = nil)
  if valid_613439 != nil:
    section.add "restapi_id", valid_613439
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613440 = query.getOrDefault("limit")
  valid_613440 = validateParameter(valid_613440, JInt, required = false, default = nil)
  if valid_613440 != nil:
    section.add "limit", valid_613440
  var valid_613441 = query.getOrDefault("position")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "position", valid_613441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613442 = header.getOrDefault("X-Amz-Signature")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Signature", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Content-Sha256", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Date")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Date", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Credential")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Credential", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Security-Token")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Security-Token", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Algorithm")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Algorithm", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-SignedHeaders", valid_613448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613449: Call_GetDocumentationVersions_613436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613449.validator(path, query, header, formData, body)
  let scheme = call_613449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613449.url(scheme.get, call_613449.host, call_613449.base,
                         call_613449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613449, url, valid)

proc call*(call_613450: Call_GetDocumentationVersions_613436; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDocumentationVersions
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613451 = newJObject()
  var query_613452 = newJObject()
  add(query_613452, "limit", newJInt(limit))
  add(query_613452, "position", newJString(position))
  add(path_613451, "restapi_id", newJString(restapiId))
  result = call_613450.call(path_613451, query_613452, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_613436(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_613437, base: "/",
    url: url_GetDocumentationVersions_613438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_613484 = ref object of OpenApiRestCall_612642
proc url_CreateDomainName_613486(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainName_613485(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new domain name.
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
  var valid_613487 = header.getOrDefault("X-Amz-Signature")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Signature", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Content-Sha256", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Date")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Date", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Credential")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Credential", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Security-Token")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Security-Token", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Algorithm")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Algorithm", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-SignedHeaders", valid_613493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613495: Call_CreateDomainName_613484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_613495.validator(path, query, header, formData, body)
  let scheme = call_613495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613495.url(scheme.get, call_613495.host, call_613495.base,
                         call_613495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613495, url, valid)

proc call*(call_613496: Call_CreateDomainName_613484; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_613497 = newJObject()
  if body != nil:
    body_613497 = body
  result = call_613496.call(nil, nil, nil, nil, body_613497)

var createDomainName* = Call_CreateDomainName_613484(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_613485, base: "/",
    url: url_CreateDomainName_613486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_613469 = ref object of OpenApiRestCall_612642
proc url_GetDomainNames_613471(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainNames_613470(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613472 = query.getOrDefault("limit")
  valid_613472 = validateParameter(valid_613472, JInt, required = false, default = nil)
  if valid_613472 != nil:
    section.add "limit", valid_613472
  var valid_613473 = query.getOrDefault("position")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "position", valid_613473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613474 = header.getOrDefault("X-Amz-Signature")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Signature", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Content-Sha256", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Date")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Date", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Credential")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Credential", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Security-Token")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Security-Token", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Algorithm")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Algorithm", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-SignedHeaders", valid_613480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613481: Call_GetDomainNames_613469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_613481.validator(path, query, header, formData, body)
  let scheme = call_613481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613481.url(scheme.get, call_613481.host, call_613481.base,
                         call_613481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613481, url, valid)

proc call*(call_613482: Call_GetDomainNames_613469; limit: int = 0;
          position: string = ""): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_613483 = newJObject()
  add(query_613483, "limit", newJInt(limit))
  add(query_613483, "position", newJString(position))
  result = call_613482.call(nil, query_613483, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_613469(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_613470, base: "/",
    url: url_GetDomainNames_613471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_613515 = ref object of OpenApiRestCall_612642
proc url_CreateModel_613517(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_CreateModel_613516(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613518 = path.getOrDefault("restapi_id")
  valid_613518 = validateParameter(valid_613518, JString, required = true,
                                 default = nil)
  if valid_613518 != nil:
    section.add "restapi_id", valid_613518
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
  var valid_613519 = header.getOrDefault("X-Amz-Signature")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Signature", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Content-Sha256", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Date")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Date", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Credential")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Credential", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Security-Token")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Security-Token", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Algorithm")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Algorithm", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-SignedHeaders", valid_613525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613527: Call_CreateModel_613515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_613527.validator(path, query, header, formData, body)
  let scheme = call_613527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613527.url(scheme.get, call_613527.host, call_613527.base,
                         call_613527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613527, url, valid)

proc call*(call_613528: Call_CreateModel_613515; restapiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  ##   body: JObject (required)
  var path_613529 = newJObject()
  var body_613530 = newJObject()
  add(path_613529, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613530 = body
  result = call_613528.call(path_613529, nil, nil, nil, body_613530)

var createModel* = Call_CreateModel_613515(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_613516,
                                        base: "/", url: url_CreateModel_613517,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_613498 = ref object of OpenApiRestCall_612642
proc url_GetModels_613500(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_GetModels_613499(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613501 = path.getOrDefault("restapi_id")
  valid_613501 = validateParameter(valid_613501, JString, required = true,
                                 default = nil)
  if valid_613501 != nil:
    section.add "restapi_id", valid_613501
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613502 = query.getOrDefault("limit")
  valid_613502 = validateParameter(valid_613502, JInt, required = false, default = nil)
  if valid_613502 != nil:
    section.add "limit", valid_613502
  var valid_613503 = query.getOrDefault("position")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "position", valid_613503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613504 = header.getOrDefault("X-Amz-Signature")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Signature", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Content-Sha256", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Date")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Date", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Credential")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Credential", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Security-Token")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Security-Token", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Algorithm")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Algorithm", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-SignedHeaders", valid_613510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613511: Call_GetModels_613498; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_613511.validator(path, query, header, formData, body)
  let scheme = call_613511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613511.url(scheme.get, call_613511.host, call_613511.base,
                         call_613511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613511, url, valid)

proc call*(call_613512: Call_GetModels_613498; restapiId: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613513 = newJObject()
  var query_613514 = newJObject()
  add(query_613514, "limit", newJInt(limit))
  add(query_613514, "position", newJString(position))
  add(path_613513, "restapi_id", newJString(restapiId))
  result = call_613512.call(path_613513, query_613514, nil, nil, nil)

var getModels* = Call_GetModels_613498(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_613499,
                                    base: "/", url: url_GetModels_613500,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_613548 = ref object of OpenApiRestCall_612642
proc url_CreateRequestValidator_613550(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/requestvalidators")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRequestValidator_613549(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613551 = path.getOrDefault("restapi_id")
  valid_613551 = validateParameter(valid_613551, JString, required = true,
                                 default = nil)
  if valid_613551 != nil:
    section.add "restapi_id", valid_613551
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
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Security-Token")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Security-Token", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Algorithm")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Algorithm", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-SignedHeaders", valid_613558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_CreateRequestValidator_613548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_CreateRequestValidator_613548; restapiId: string;
          body: JsonNode): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613562 = newJObject()
  var body_613563 = newJObject()
  add(path_613562, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613563 = body
  result = call_613561.call(path_613562, nil, nil, nil, body_613563)

var createRequestValidator* = Call_CreateRequestValidator_613548(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_613549, base: "/",
    url: url_CreateRequestValidator_613550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_613531 = ref object of OpenApiRestCall_612642
proc url_GetRequestValidators_613533(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/requestvalidators")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRequestValidators_613532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613534 = path.getOrDefault("restapi_id")
  valid_613534 = validateParameter(valid_613534, JString, required = true,
                                 default = nil)
  if valid_613534 != nil:
    section.add "restapi_id", valid_613534
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613535 = query.getOrDefault("limit")
  valid_613535 = validateParameter(valid_613535, JInt, required = false, default = nil)
  if valid_613535 != nil:
    section.add "limit", valid_613535
  var valid_613536 = query.getOrDefault("position")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "position", valid_613536
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613537 = header.getOrDefault("X-Amz-Signature")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Signature", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Content-Sha256", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Date")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Date", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Credential")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Credential", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Security-Token")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Security-Token", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Algorithm")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Algorithm", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-SignedHeaders", valid_613543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613544: Call_GetRequestValidators_613531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_613544.validator(path, query, header, formData, body)
  let scheme = call_613544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613544.url(scheme.get, call_613544.host, call_613544.base,
                         call_613544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613544, url, valid)

proc call*(call_613545: Call_GetRequestValidators_613531; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613546 = newJObject()
  var query_613547 = newJObject()
  add(query_613547, "limit", newJInt(limit))
  add(query_613547, "position", newJString(position))
  add(path_613546, "restapi_id", newJString(restapiId))
  result = call_613545.call(path_613546, query_613547, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_613531(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_613532, base: "/",
    url: url_GetRequestValidators_613533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_613564 = ref object of OpenApiRestCall_612642
proc url_CreateResource_613566(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "parent_id" in path, "`parent_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "parent_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResource_613565(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a <a>Resource</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   parent_id: JString (required)
  ##            : [Required] The parent resource's identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613567 = path.getOrDefault("restapi_id")
  valid_613567 = validateParameter(valid_613567, JString, required = true,
                                 default = nil)
  if valid_613567 != nil:
    section.add "restapi_id", valid_613567
  var valid_613568 = path.getOrDefault("parent_id")
  valid_613568 = validateParameter(valid_613568, JString, required = true,
                                 default = nil)
  if valid_613568 != nil:
    section.add "parent_id", valid_613568
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
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_CreateResource_613564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_CreateResource_613564; restapiId: string;
          body: JsonNode; parentId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  var path_613579 = newJObject()
  var body_613580 = newJObject()
  add(path_613579, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613580 = body
  add(path_613579, "parent_id", newJString(parentId))
  result = call_613578.call(path_613579, nil, nil, nil, body_613580)

var createResource* = Call_CreateResource_613564(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_613565, base: "/", url: url_CreateResource_613566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_613596 = ref object of OpenApiRestCall_612642
proc url_CreateRestApi_613598(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRestApi_613597(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new <a>RestApi</a> resource.
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
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_CreateRestApi_613596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_CreateRestApi_613596; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_613609 = newJObject()
  if body != nil:
    body_613609 = body
  result = call_613608.call(nil, nil, nil, nil, body_613609)

var createRestApi* = Call_CreateRestApi_613596(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_613597, base: "/", url: url_CreateRestApi_613598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_613581 = ref object of OpenApiRestCall_612642
proc url_GetRestApis_613583(protocol: Scheme; host: string; base: string;
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

proc validate_GetRestApis_613582(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613584 = query.getOrDefault("limit")
  valid_613584 = validateParameter(valid_613584, JInt, required = false, default = nil)
  if valid_613584 != nil:
    section.add "limit", valid_613584
  var valid_613585 = query.getOrDefault("position")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "position", valid_613585
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613586 = header.getOrDefault("X-Amz-Signature")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Signature", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Content-Sha256", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Date")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Date", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Credential")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Credential", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Security-Token")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Security-Token", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Algorithm")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Algorithm", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-SignedHeaders", valid_613592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613593: Call_GetRestApis_613581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_613593.validator(path, query, header, formData, body)
  let scheme = call_613593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613593.url(scheme.get, call_613593.host, call_613593.base,
                         call_613593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613593, url, valid)

proc call*(call_613594: Call_GetRestApis_613581; limit: int = 0; position: string = ""): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_613595 = newJObject()
  add(query_613595, "limit", newJInt(limit))
  add(query_613595, "position", newJString(position))
  result = call_613594.call(nil, query_613595, nil, nil, nil)

var getRestApis* = Call_GetRestApis_613581(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_613582,
                                        base: "/", url: url_GetRestApis_613583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_613626 = ref object of OpenApiRestCall_612642
proc url_CreateStage_613628(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_CreateStage_613627(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613629 = path.getOrDefault("restapi_id")
  valid_613629 = validateParameter(valid_613629, JString, required = true,
                                 default = nil)
  if valid_613629 != nil:
    section.add "restapi_id", valid_613629
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
  var valid_613630 = header.getOrDefault("X-Amz-Signature")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Signature", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Content-Sha256", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Date")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Date", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Credential")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Credential", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Security-Token")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Security-Token", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Algorithm")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Algorithm", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-SignedHeaders", valid_613636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613638: Call_CreateStage_613626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_613638.validator(path, query, header, formData, body)
  let scheme = call_613638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613638.url(scheme.get, call_613638.host, call_613638.base,
                         call_613638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613638, url, valid)

proc call*(call_613639: Call_CreateStage_613626; restapiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613640 = newJObject()
  var body_613641 = newJObject()
  add(path_613640, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613641 = body
  result = call_613639.call(path_613640, nil, nil, nil, body_613641)

var createStage* = Call_CreateStage_613626(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_613627,
                                        base: "/", url: url_CreateStage_613628,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_613610 = ref object of OpenApiRestCall_612642
proc url_GetStages_613612(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
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

proc validate_GetStages_613611(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613613 = path.getOrDefault("restapi_id")
  valid_613613 = validateParameter(valid_613613, JString, required = true,
                                 default = nil)
  if valid_613613 != nil:
    section.add "restapi_id", valid_613613
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_613614 = query.getOrDefault("deploymentId")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "deploymentId", valid_613614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613615 = header.getOrDefault("X-Amz-Signature")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Signature", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Content-Sha256", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Date")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Date", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Credential")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Credential", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Security-Token")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Security-Token", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Algorithm")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Algorithm", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-SignedHeaders", valid_613621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613622: Call_GetStages_613610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_613622.validator(path, query, header, formData, body)
  let scheme = call_613622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613622.url(scheme.get, call_613622.host, call_613622.base,
                         call_613622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613622, url, valid)

proc call*(call_613623: Call_GetStages_613610; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  var path_613624 = newJObject()
  var query_613625 = newJObject()
  add(path_613624, "restapi_id", newJString(restapiId))
  add(query_613625, "deploymentId", newJString(deploymentId))
  result = call_613623.call(path_613624, query_613625, nil, nil, nil)

var getStages* = Call_GetStages_613610(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_613611,
                                    base: "/", url: url_GetStages_613612,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_613658 = ref object of OpenApiRestCall_612642
proc url_CreateUsagePlan_613660(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlan_613659(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
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
  var valid_613661 = header.getOrDefault("X-Amz-Signature")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Signature", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Content-Sha256", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Date")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Date", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Credential")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Credential", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Security-Token")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Security-Token", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Algorithm")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Algorithm", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-SignedHeaders", valid_613667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613669: Call_CreateUsagePlan_613658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_613669.validator(path, query, header, formData, body)
  let scheme = call_613669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613669.url(scheme.get, call_613669.host, call_613669.base,
                         call_613669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613669, url, valid)

proc call*(call_613670: Call_CreateUsagePlan_613658; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_613671 = newJObject()
  if body != nil:
    body_613671 = body
  result = call_613670.call(nil, nil, nil, nil, body_613671)

var createUsagePlan* = Call_CreateUsagePlan_613658(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_613659, base: "/",
    url: url_CreateUsagePlan_613660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_613642 = ref object of OpenApiRestCall_612642
proc url_GetUsagePlans_613644(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlans_613643(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the usage plans of the caller's account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   keyId: JString
  ##        : The identifier of the API key associated with the usage plans.
  section = newJObject()
  var valid_613645 = query.getOrDefault("limit")
  valid_613645 = validateParameter(valid_613645, JInt, required = false, default = nil)
  if valid_613645 != nil:
    section.add "limit", valid_613645
  var valid_613646 = query.getOrDefault("position")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "position", valid_613646
  var valid_613647 = query.getOrDefault("keyId")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "keyId", valid_613647
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_613655: Call_GetUsagePlans_613642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_613655.validator(path, query, header, formData, body)
  let scheme = call_613655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613655.url(scheme.get, call_613655.host, call_613655.base,
                         call_613655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613655, url, valid)

proc call*(call_613656: Call_GetUsagePlans_613642; limit: int = 0;
          position: string = ""; keyId: string = ""): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  var query_613657 = newJObject()
  add(query_613657, "limit", newJInt(limit))
  add(query_613657, "position", newJString(position))
  add(query_613657, "keyId", newJString(keyId))
  result = call_613656.call(nil, query_613657, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_613642(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_613643, base: "/",
    url: url_GetUsagePlans_613644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_613690 = ref object of OpenApiRestCall_612642
proc url_CreateUsagePlanKey_613692(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/keys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUsagePlanKey_613691(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_613693 = path.getOrDefault("usageplanId")
  valid_613693 = validateParameter(valid_613693, JString, required = true,
                                 default = nil)
  if valid_613693 != nil:
    section.add "usageplanId", valid_613693
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
  var valid_613694 = header.getOrDefault("X-Amz-Signature")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Signature", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Content-Sha256", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Date")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Date", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Credential")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Credential", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Security-Token")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Security-Token", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Algorithm")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Algorithm", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-SignedHeaders", valid_613700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613702: Call_CreateUsagePlanKey_613690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_613702.validator(path, query, header, formData, body)
  let scheme = call_613702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613702.url(scheme.get, call_613702.host, call_613702.base,
                         call_613702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613702, url, valid)

proc call*(call_613703: Call_CreateUsagePlanKey_613690; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_613704 = newJObject()
  var body_613705 = newJObject()
  add(path_613704, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_613705 = body
  result = call_613703.call(path_613704, nil, nil, nil, body_613705)

var createUsagePlanKey* = Call_CreateUsagePlanKey_613690(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_613691, base: "/",
    url: url_CreateUsagePlanKey_613692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_613672 = ref object of OpenApiRestCall_612642
proc url_GetUsagePlanKeys_613674(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/keys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsagePlanKeys_613673(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_613675 = path.getOrDefault("usageplanId")
  valid_613675 = validateParameter(valid_613675, JString, required = true,
                                 default = nil)
  if valid_613675 != nil:
    section.add "usageplanId", valid_613675
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613676 = query.getOrDefault("name")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "name", valid_613676
  var valid_613677 = query.getOrDefault("limit")
  valid_613677 = validateParameter(valid_613677, JInt, required = false, default = nil)
  if valid_613677 != nil:
    section.add "limit", valid_613677
  var valid_613678 = query.getOrDefault("position")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "position", valid_613678
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_613686: Call_GetUsagePlanKeys_613672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_613686.validator(path, query, header, formData, body)
  let scheme = call_613686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613686.url(scheme.get, call_613686.host, call_613686.base,
                         call_613686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613686, url, valid)

proc call*(call_613687: Call_GetUsagePlanKeys_613672; usageplanId: string;
          name: string = ""; limit: int = 0; position: string = ""): Recallable =
  ## getUsagePlanKeys
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ##   name: string
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var path_613688 = newJObject()
  var query_613689 = newJObject()
  add(query_613689, "name", newJString(name))
  add(path_613688, "usageplanId", newJString(usageplanId))
  add(query_613689, "limit", newJInt(limit))
  add(query_613689, "position", newJString(position))
  result = call_613687.call(path_613688, query_613689, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_613672(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_613673,
    base: "/", url: url_GetUsagePlanKeys_613674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_613721 = ref object of OpenApiRestCall_612642
proc url_CreateVpcLink_613723(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVpcLink_613722(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
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
  var valid_613724 = header.getOrDefault("X-Amz-Signature")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Signature", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Content-Sha256", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Date")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Date", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Credential")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Credential", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Security-Token")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Security-Token", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Algorithm")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Algorithm", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-SignedHeaders", valid_613730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613732: Call_CreateVpcLink_613721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_613732.validator(path, query, header, formData, body)
  let scheme = call_613732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613732.url(scheme.get, call_613732.host, call_613732.base,
                         call_613732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613732, url, valid)

proc call*(call_613733: Call_CreateVpcLink_613721; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_613734 = newJObject()
  if body != nil:
    body_613734 = body
  result = call_613733.call(nil, nil, nil, nil, body_613734)

var createVpcLink* = Call_CreateVpcLink_613721(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_613722, base: "/", url: url_CreateVpcLink_613723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_613706 = ref object of OpenApiRestCall_612642
proc url_GetVpcLinks_613708(protocol: Scheme; host: string; base: string;
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

proc validate_GetVpcLinks_613707(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_613709 = query.getOrDefault("limit")
  valid_613709 = validateParameter(valid_613709, JInt, required = false, default = nil)
  if valid_613709 != nil:
    section.add "limit", valid_613709
  var valid_613710 = query.getOrDefault("position")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "position", valid_613710
  result.add "query", section
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

proc call*(call_613718: Call_GetVpcLinks_613706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_613718.validator(path, query, header, formData, body)
  let scheme = call_613718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613718.url(scheme.get, call_613718.host, call_613718.base,
                         call_613718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613718, url, valid)

proc call*(call_613719: Call_GetVpcLinks_613706; limit: int = 0; position: string = ""): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_613720 = newJObject()
  add(query_613720, "limit", newJInt(limit))
  add(query_613720, "position", newJString(position))
  result = call_613719.call(nil, query_613720, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_613706(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_613707,
                                        base: "/", url: url_GetVpcLinks_613708,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_613735 = ref object of OpenApiRestCall_612642
proc url_GetApiKey_613737(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiKey_613736(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   api_Key: JString (required)
  ##          : [Required] The identifier of the <a>ApiKey</a> resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `api_Key` field"
  var valid_613738 = path.getOrDefault("api_Key")
  valid_613738 = validateParameter(valid_613738, JString, required = true,
                                 default = nil)
  if valid_613738 != nil:
    section.add "api_Key", valid_613738
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_613739 = query.getOrDefault("includeValue")
  valid_613739 = validateParameter(valid_613739, JBool, required = false, default = nil)
  if valid_613739 != nil:
    section.add "includeValue", valid_613739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613740 = header.getOrDefault("X-Amz-Signature")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Signature", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Content-Sha256", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Date")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Date", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Credential")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Credential", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Security-Token")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Security-Token", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Algorithm")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Algorithm", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-SignedHeaders", valid_613746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613747: Call_GetApiKey_613735; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_613747.validator(path, query, header, formData, body)
  let scheme = call_613747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613747.url(scheme.get, call_613747.host, call_613747.base,
                         call_613747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613747, url, valid)

proc call*(call_613748: Call_GetApiKey_613735; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_613749 = newJObject()
  var query_613750 = newJObject()
  add(query_613750, "includeValue", newJBool(includeValue))
  add(path_613749, "api_Key", newJString(apiKey))
  result = call_613748.call(path_613749, query_613750, nil, nil, nil)

var getApiKey* = Call_GetApiKey_613735(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_613736,
                                    base: "/", url: url_GetApiKey_613737,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_613765 = ref object of OpenApiRestCall_612642
proc url_UpdateApiKey_613767(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiKey_613766(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   api_Key: JString (required)
  ##          : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `api_Key` field"
  var valid_613768 = path.getOrDefault("api_Key")
  valid_613768 = validateParameter(valid_613768, JString, required = true,
                                 default = nil)
  if valid_613768 != nil:
    section.add "api_Key", valid_613768
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
  var valid_613769 = header.getOrDefault("X-Amz-Signature")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Signature", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Content-Sha256", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Date")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Date", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Credential")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Credential", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Security-Token")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Security-Token", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Algorithm")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Algorithm", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-SignedHeaders", valid_613775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613777: Call_UpdateApiKey_613765; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_613777.validator(path, query, header, formData, body)
  let scheme = call_613777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613777.url(scheme.get, call_613777.host, call_613777.base,
                         call_613777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613777, url, valid)

proc call*(call_613778: Call_UpdateApiKey_613765; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_613779 = newJObject()
  var body_613780 = newJObject()
  add(path_613779, "api_Key", newJString(apiKey))
  if body != nil:
    body_613780 = body
  result = call_613778.call(path_613779, nil, nil, nil, body_613780)

var updateApiKey* = Call_UpdateApiKey_613765(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_613766, base: "/",
    url: url_UpdateApiKey_613767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_613751 = ref object of OpenApiRestCall_612642
proc url_DeleteApiKey_613753(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiKey_613752(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   api_Key: JString (required)
  ##          : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `api_Key` field"
  var valid_613754 = path.getOrDefault("api_Key")
  valid_613754 = validateParameter(valid_613754, JString, required = true,
                                 default = nil)
  if valid_613754 != nil:
    section.add "api_Key", valid_613754
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
  var valid_613755 = header.getOrDefault("X-Amz-Signature")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Signature", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Content-Sha256", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Date")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Date", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Credential")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Credential", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Security-Token")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Security-Token", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Algorithm")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Algorithm", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-SignedHeaders", valid_613761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613762: Call_DeleteApiKey_613751; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_613762.validator(path, query, header, formData, body)
  let scheme = call_613762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613762.url(scheme.get, call_613762.host, call_613762.base,
                         call_613762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613762, url, valid)

proc call*(call_613763: Call_DeleteApiKey_613751; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_613764 = newJObject()
  add(path_613764, "api_Key", newJString(apiKey))
  result = call_613763.call(path_613764, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_613751(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_613752, base: "/",
    url: url_DeleteApiKey_613753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_613796 = ref object of OpenApiRestCall_612642
proc url_TestInvokeAuthorizer_613798(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "authorizer_id" in path, "`authorizer_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizer_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TestInvokeAuthorizer_613797(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizer_id: JString (required)
  ##                : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613799 = path.getOrDefault("restapi_id")
  valid_613799 = validateParameter(valid_613799, JString, required = true,
                                 default = nil)
  if valid_613799 != nil:
    section.add "restapi_id", valid_613799
  var valid_613800 = path.getOrDefault("authorizer_id")
  valid_613800 = validateParameter(valid_613800, JString, required = true,
                                 default = nil)
  if valid_613800 != nil:
    section.add "authorizer_id", valid_613800
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
  var valid_613801 = header.getOrDefault("X-Amz-Signature")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Signature", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Content-Sha256", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Date")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Date", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Credential")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Credential", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Security-Token")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Security-Token", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Algorithm")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Algorithm", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-SignedHeaders", valid_613807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613809: Call_TestInvokeAuthorizer_613796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_613809.validator(path, query, header, formData, body)
  let scheme = call_613809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613809.url(scheme.get, call_613809.host, call_613809.base,
                         call_613809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613809, url, valid)

proc call*(call_613810: Call_TestInvokeAuthorizer_613796; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  var path_613811 = newJObject()
  var body_613812 = newJObject()
  add(path_613811, "restapi_id", newJString(restapiId))
  add(path_613811, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_613812 = body
  result = call_613810.call(path_613811, nil, nil, nil, body_613812)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_613796(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_613797, base: "/",
    url: url_TestInvokeAuthorizer_613798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_613781 = ref object of OpenApiRestCall_612642
proc url_GetAuthorizer_613783(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "authorizer_id" in path, "`authorizer_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizer_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizer_613782(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizer_id: JString (required)
  ##                : [Required] The identifier of the <a>Authorizer</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613784 = path.getOrDefault("restapi_id")
  valid_613784 = validateParameter(valid_613784, JString, required = true,
                                 default = nil)
  if valid_613784 != nil:
    section.add "restapi_id", valid_613784
  var valid_613785 = path.getOrDefault("authorizer_id")
  valid_613785 = validateParameter(valid_613785, JString, required = true,
                                 default = nil)
  if valid_613785 != nil:
    section.add "authorizer_id", valid_613785
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
  var valid_613786 = header.getOrDefault("X-Amz-Signature")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Signature", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Content-Sha256", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Date")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Date", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Credential")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Credential", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Security-Token")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Security-Token", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Algorithm")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Algorithm", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-SignedHeaders", valid_613792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613793: Call_GetAuthorizer_613781; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_613793.validator(path, query, header, formData, body)
  let scheme = call_613793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613793.url(scheme.get, call_613793.host, call_613793.base,
                         call_613793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613793, url, valid)

proc call*(call_613794: Call_GetAuthorizer_613781; restapiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_613795 = newJObject()
  add(path_613795, "restapi_id", newJString(restapiId))
  add(path_613795, "authorizer_id", newJString(authorizerId))
  result = call_613794.call(path_613795, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_613781(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_613782, base: "/", url: url_GetAuthorizer_613783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_613828 = ref object of OpenApiRestCall_612642
proc url_UpdateAuthorizer_613830(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "authorizer_id" in path, "`authorizer_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizer_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAuthorizer_613829(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizer_id: JString (required)
  ##                : [Required] The identifier of the <a>Authorizer</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613831 = path.getOrDefault("restapi_id")
  valid_613831 = validateParameter(valid_613831, JString, required = true,
                                 default = nil)
  if valid_613831 != nil:
    section.add "restapi_id", valid_613831
  var valid_613832 = path.getOrDefault("authorizer_id")
  valid_613832 = validateParameter(valid_613832, JString, required = true,
                                 default = nil)
  if valid_613832 != nil:
    section.add "authorizer_id", valid_613832
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
  var valid_613833 = header.getOrDefault("X-Amz-Signature")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Signature", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Content-Sha256", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Date")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Date", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Credential")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Credential", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Security-Token")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Security-Token", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-Algorithm")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-Algorithm", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-SignedHeaders", valid_613839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613841: Call_UpdateAuthorizer_613828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_613841.validator(path, query, header, formData, body)
  let scheme = call_613841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613841.url(scheme.get, call_613841.host, call_613841.base,
                         call_613841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613841, url, valid)

proc call*(call_613842: Call_UpdateAuthorizer_613828; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  var path_613843 = newJObject()
  var body_613844 = newJObject()
  add(path_613843, "restapi_id", newJString(restapiId))
  add(path_613843, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_613844 = body
  result = call_613842.call(path_613843, nil, nil, nil, body_613844)

var updateAuthorizer* = Call_UpdateAuthorizer_613828(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_613829, base: "/",
    url: url_UpdateAuthorizer_613830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_613813 = ref object of OpenApiRestCall_612642
proc url_DeleteAuthorizer_613815(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "authorizer_id" in path, "`authorizer_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizer_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAuthorizer_613814(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizer_id: JString (required)
  ##                : [Required] The identifier of the <a>Authorizer</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_613816 = path.getOrDefault("restapi_id")
  valid_613816 = validateParameter(valid_613816, JString, required = true,
                                 default = nil)
  if valid_613816 != nil:
    section.add "restapi_id", valid_613816
  var valid_613817 = path.getOrDefault("authorizer_id")
  valid_613817 = validateParameter(valid_613817, JString, required = true,
                                 default = nil)
  if valid_613817 != nil:
    section.add "authorizer_id", valid_613817
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
  var valid_613818 = header.getOrDefault("X-Amz-Signature")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Signature", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Content-Sha256", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Date")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Date", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Credential")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Credential", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Security-Token")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Security-Token", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Algorithm")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Algorithm", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-SignedHeaders", valid_613824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613825: Call_DeleteAuthorizer_613813; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_613825.validator(path, query, header, formData, body)
  let scheme = call_613825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613825.url(scheme.get, call_613825.host, call_613825.base,
                         call_613825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613825, url, valid)

proc call*(call_613826: Call_DeleteAuthorizer_613813; restapiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_613827 = newJObject()
  add(path_613827, "restapi_id", newJString(restapiId))
  add(path_613827, "authorizer_id", newJString(authorizerId))
  result = call_613826.call(path_613827, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_613813(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_613814, base: "/",
    url: url_DeleteAuthorizer_613815, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_613845 = ref object of OpenApiRestCall_612642
proc url_GetBasePathMapping_613847(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  assert "base_path" in path, "`base_path` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name"),
               (kind: ConstantSegment, value: "/basepathmappings/"),
               (kind: VariableSegment, value: "base_path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBasePathMapping_613846(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   base_path: JString (required)
  ##            : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domain_name: JString (required)
  ##              : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `base_path` field"
  var valid_613848 = path.getOrDefault("base_path")
  valid_613848 = validateParameter(valid_613848, JString, required = true,
                                 default = nil)
  if valid_613848 != nil:
    section.add "base_path", valid_613848
  var valid_613849 = path.getOrDefault("domain_name")
  valid_613849 = validateParameter(valid_613849, JString, required = true,
                                 default = nil)
  if valid_613849 != nil:
    section.add "domain_name", valid_613849
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

proc call*(call_613857: Call_GetBasePathMapping_613845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_613857.validator(path, query, header, formData, body)
  let scheme = call_613857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613857.url(scheme.get, call_613857.host, call_613857.base,
                         call_613857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613857, url, valid)

proc call*(call_613858: Call_GetBasePathMapping_613845; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_613859 = newJObject()
  add(path_613859, "base_path", newJString(basePath))
  add(path_613859, "domain_name", newJString(domainName))
  result = call_613858.call(path_613859, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_613845(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_613846, base: "/",
    url: url_GetBasePathMapping_613847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_613875 = ref object of OpenApiRestCall_612642
proc url_UpdateBasePathMapping_613877(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  assert "base_path" in path, "`base_path` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name"),
               (kind: ConstantSegment, value: "/basepathmappings/"),
               (kind: VariableSegment, value: "base_path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBasePathMapping_613876(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   base_path: JString (required)
  ##            : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domain_name: JString (required)
  ##              : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `base_path` field"
  var valid_613878 = path.getOrDefault("base_path")
  valid_613878 = validateParameter(valid_613878, JString, required = true,
                                 default = nil)
  if valid_613878 != nil:
    section.add "base_path", valid_613878
  var valid_613879 = path.getOrDefault("domain_name")
  valid_613879 = validateParameter(valid_613879, JString, required = true,
                                 default = nil)
  if valid_613879 != nil:
    section.add "domain_name", valid_613879
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
  var valid_613880 = header.getOrDefault("X-Amz-Signature")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Signature", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Content-Sha256", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Date")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Date", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Credential")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Credential", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Security-Token")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Security-Token", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Algorithm")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Algorithm", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-SignedHeaders", valid_613886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613888: Call_UpdateBasePathMapping_613875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_613888.validator(path, query, header, formData, body)
  let scheme = call_613888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613888.url(scheme.get, call_613888.host, call_613888.base,
                         call_613888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613888, url, valid)

proc call*(call_613889: Call_UpdateBasePathMapping_613875; basePath: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  var path_613890 = newJObject()
  var body_613891 = newJObject()
  add(path_613890, "base_path", newJString(basePath))
  if body != nil:
    body_613891 = body
  add(path_613890, "domain_name", newJString(domainName))
  result = call_613889.call(path_613890, nil, nil, nil, body_613891)

var updateBasePathMapping* = Call_UpdateBasePathMapping_613875(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_613876, base: "/",
    url: url_UpdateBasePathMapping_613877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_613860 = ref object of OpenApiRestCall_612642
proc url_DeleteBasePathMapping_613862(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  assert "base_path" in path, "`base_path` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name"),
               (kind: ConstantSegment, value: "/basepathmappings/"),
               (kind: VariableSegment, value: "base_path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBasePathMapping_613861(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   base_path: JString (required)
  ##            : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domain_name: JString (required)
  ##              : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `base_path` field"
  var valid_613863 = path.getOrDefault("base_path")
  valid_613863 = validateParameter(valid_613863, JString, required = true,
                                 default = nil)
  if valid_613863 != nil:
    section.add "base_path", valid_613863
  var valid_613864 = path.getOrDefault("domain_name")
  valid_613864 = validateParameter(valid_613864, JString, required = true,
                                 default = nil)
  if valid_613864 != nil:
    section.add "domain_name", valid_613864
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
  var valid_613865 = header.getOrDefault("X-Amz-Signature")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Signature", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Content-Sha256", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Date")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Date", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Credential")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Credential", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Security-Token")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Security-Token", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Algorithm")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Algorithm", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-SignedHeaders", valid_613871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613872: Call_DeleteBasePathMapping_613860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_613872.validator(path, query, header, formData, body)
  let scheme = call_613872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613872.url(scheme.get, call_613872.host, call_613872.base,
                         call_613872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613872, url, valid)

proc call*(call_613873: Call_DeleteBasePathMapping_613860; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_613874 = newJObject()
  add(path_613874, "base_path", newJString(basePath))
  add(path_613874, "domain_name", newJString(domainName))
  result = call_613873.call(path_613874, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_613860(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_613861, base: "/",
    url: url_DeleteBasePathMapping_613862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_613892 = ref object of OpenApiRestCall_612642
proc url_GetClientCertificate_613894(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clientcertificate_id" in path,
        "`clientcertificate_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clientcertificates/"),
               (kind: VariableSegment, value: "clientcertificate_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetClientCertificate_613893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clientcertificate_id: JString (required)
  ##                       : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `clientcertificate_id` field"
  var valid_613895 = path.getOrDefault("clientcertificate_id")
  valid_613895 = validateParameter(valid_613895, JString, required = true,
                                 default = nil)
  if valid_613895 != nil:
    section.add "clientcertificate_id", valid_613895
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
  var valid_613896 = header.getOrDefault("X-Amz-Signature")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Signature", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Content-Sha256", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Date")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Date", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Credential")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Credential", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Security-Token")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Security-Token", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Algorithm")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Algorithm", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-SignedHeaders", valid_613902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613903: Call_GetClientCertificate_613892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_613903.validator(path, query, header, formData, body)
  let scheme = call_613903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613903.url(scheme.get, call_613903.host, call_613903.base,
                         call_613903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613903, url, valid)

proc call*(call_613904: Call_GetClientCertificate_613892;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_613905 = newJObject()
  add(path_613905, "clientcertificate_id", newJString(clientcertificateId))
  result = call_613904.call(path_613905, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_613892(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_613893, base: "/",
    url: url_GetClientCertificate_613894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_613920 = ref object of OpenApiRestCall_612642
proc url_UpdateClientCertificate_613922(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clientcertificate_id" in path,
        "`clientcertificate_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clientcertificates/"),
               (kind: VariableSegment, value: "clientcertificate_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClientCertificate_613921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clientcertificate_id: JString (required)
  ##                       : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `clientcertificate_id` field"
  var valid_613923 = path.getOrDefault("clientcertificate_id")
  valid_613923 = validateParameter(valid_613923, JString, required = true,
                                 default = nil)
  if valid_613923 != nil:
    section.add "clientcertificate_id", valid_613923
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
  var valid_613924 = header.getOrDefault("X-Amz-Signature")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Signature", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Content-Sha256", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Date")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Date", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Credential")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Credential", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Security-Token")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Security-Token", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Algorithm")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Algorithm", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-SignedHeaders", valid_613930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613932: Call_UpdateClientCertificate_613920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_613932.validator(path, query, header, formData, body)
  let scheme = call_613932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613932.url(scheme.get, call_613932.host, call_613932.base,
                         call_613932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613932, url, valid)

proc call*(call_613933: Call_UpdateClientCertificate_613920;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_613934 = newJObject()
  var body_613935 = newJObject()
  add(path_613934, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_613935 = body
  result = call_613933.call(path_613934, nil, nil, nil, body_613935)

var updateClientCertificate* = Call_UpdateClientCertificate_613920(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_613921, base: "/",
    url: url_UpdateClientCertificate_613922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_613906 = ref object of OpenApiRestCall_612642
proc url_DeleteClientCertificate_613908(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clientcertificate_id" in path,
        "`clientcertificate_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clientcertificates/"),
               (kind: VariableSegment, value: "clientcertificate_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteClientCertificate_613907(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clientcertificate_id: JString (required)
  ##                       : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `clientcertificate_id` field"
  var valid_613909 = path.getOrDefault("clientcertificate_id")
  valid_613909 = validateParameter(valid_613909, JString, required = true,
                                 default = nil)
  if valid_613909 != nil:
    section.add "clientcertificate_id", valid_613909
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

proc call*(call_613917: Call_DeleteClientCertificate_613906; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_613917.validator(path, query, header, formData, body)
  let scheme = call_613917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613917.url(scheme.get, call_613917.host, call_613917.base,
                         call_613917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613917, url, valid)

proc call*(call_613918: Call_DeleteClientCertificate_613906;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_613919 = newJObject()
  add(path_613919, "clientcertificate_id", newJString(clientcertificateId))
  result = call_613918.call(path_613919, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_613906(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_613907, base: "/",
    url: url_DeleteClientCertificate_613908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_613936 = ref object of OpenApiRestCall_612642
proc url_GetDeployment_613938(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "deployment_id" in path, "`deployment_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deployment_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_613937(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deployment_id: JString (required)
  ##                : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `deployment_id` field"
  var valid_613939 = path.getOrDefault("deployment_id")
  valid_613939 = validateParameter(valid_613939, JString, required = true,
                                 default = nil)
  if valid_613939 != nil:
    section.add "deployment_id", valid_613939
  var valid_613940 = path.getOrDefault("restapi_id")
  valid_613940 = validateParameter(valid_613940, JString, required = true,
                                 default = nil)
  if valid_613940 != nil:
    section.add "restapi_id", valid_613940
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_613941 = query.getOrDefault("embed")
  valid_613941 = validateParameter(valid_613941, JArray, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "embed", valid_613941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613942 = header.getOrDefault("X-Amz-Signature")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Signature", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Content-Sha256", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Date")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Date", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Credential")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Credential", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Security-Token")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Security-Token", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Algorithm")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Algorithm", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-SignedHeaders", valid_613948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613949: Call_GetDeployment_613936; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_613949.validator(path, query, header, formData, body)
  let scheme = call_613949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613949.url(scheme.get, call_613949.host, call_613949.base,
                         call_613949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613949, url, valid)

proc call*(call_613950: Call_GetDeployment_613936; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  var path_613951 = newJObject()
  var query_613952 = newJObject()
  add(path_613951, "deployment_id", newJString(deploymentId))
  add(path_613951, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_613952.add "embed", embed
  result = call_613950.call(path_613951, query_613952, nil, nil, nil)

var getDeployment* = Call_GetDeployment_613936(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_613937, base: "/", url: url_GetDeployment_613938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_613968 = ref object of OpenApiRestCall_612642
proc url_UpdateDeployment_613970(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "deployment_id" in path, "`deployment_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deployment_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeployment_613969(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deployment_id: JString (required)
  ##                : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `deployment_id` field"
  var valid_613971 = path.getOrDefault("deployment_id")
  valid_613971 = validateParameter(valid_613971, JString, required = true,
                                 default = nil)
  if valid_613971 != nil:
    section.add "deployment_id", valid_613971
  var valid_613972 = path.getOrDefault("restapi_id")
  valid_613972 = validateParameter(valid_613972, JString, required = true,
                                 default = nil)
  if valid_613972 != nil:
    section.add "restapi_id", valid_613972
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
  var valid_613973 = header.getOrDefault("X-Amz-Signature")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Signature", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Content-Sha256", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Date")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Date", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Credential")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Credential", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Security-Token")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Security-Token", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Algorithm")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Algorithm", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-SignedHeaders", valid_613979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613981: Call_UpdateDeployment_613968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_613981.validator(path, query, header, formData, body)
  let scheme = call_613981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613981.url(scheme.get, call_613981.host, call_613981.base,
                         call_613981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613981, url, valid)

proc call*(call_613982: Call_UpdateDeployment_613968; deploymentId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_613983 = newJObject()
  var body_613984 = newJObject()
  add(path_613983, "deployment_id", newJString(deploymentId))
  add(path_613983, "restapi_id", newJString(restapiId))
  if body != nil:
    body_613984 = body
  result = call_613982.call(path_613983, nil, nil, nil, body_613984)

var updateDeployment* = Call_UpdateDeployment_613968(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_613969, base: "/",
    url: url_UpdateDeployment_613970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_613953 = ref object of OpenApiRestCall_612642
proc url_DeleteDeployment_613955(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "deployment_id" in path, "`deployment_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deployment_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeployment_613954(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deployment_id: JString (required)
  ##                : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `deployment_id` field"
  var valid_613956 = path.getOrDefault("deployment_id")
  valid_613956 = validateParameter(valid_613956, JString, required = true,
                                 default = nil)
  if valid_613956 != nil:
    section.add "deployment_id", valid_613956
  var valid_613957 = path.getOrDefault("restapi_id")
  valid_613957 = validateParameter(valid_613957, JString, required = true,
                                 default = nil)
  if valid_613957 != nil:
    section.add "restapi_id", valid_613957
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
  var valid_613958 = header.getOrDefault("X-Amz-Signature")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Signature", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Content-Sha256", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Date")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Date", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Credential")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Credential", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Security-Token")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Security-Token", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Algorithm")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Algorithm", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-SignedHeaders", valid_613964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613965: Call_DeleteDeployment_613953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_613965.validator(path, query, header, formData, body)
  let scheme = call_613965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613965.url(scheme.get, call_613965.host, call_613965.base,
                         call_613965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613965, url, valid)

proc call*(call_613966: Call_DeleteDeployment_613953; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613967 = newJObject()
  add(path_613967, "deployment_id", newJString(deploymentId))
  add(path_613967, "restapi_id", newJString(restapiId))
  result = call_613966.call(path_613967, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_613953(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_613954, base: "/",
    url: url_DeleteDeployment_613955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_613985 = ref object of OpenApiRestCall_612642
proc url_GetDocumentationPart_613987(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "part_id" in path, "`part_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts/"),
               (kind: VariableSegment, value: "part_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationPart_613986(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   part_id: JString (required)
  ##          : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `part_id` field"
  var valid_613988 = path.getOrDefault("part_id")
  valid_613988 = validateParameter(valid_613988, JString, required = true,
                                 default = nil)
  if valid_613988 != nil:
    section.add "part_id", valid_613988
  var valid_613989 = path.getOrDefault("restapi_id")
  valid_613989 = validateParameter(valid_613989, JString, required = true,
                                 default = nil)
  if valid_613989 != nil:
    section.add "restapi_id", valid_613989
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
  var valid_613990 = header.getOrDefault("X-Amz-Signature")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Signature", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Content-Sha256", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Date")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Date", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Credential")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Credential", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Security-Token")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Security-Token", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Algorithm")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Algorithm", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-SignedHeaders", valid_613996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_GetDocumentationPart_613985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_GetDocumentationPart_613985; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613999 = newJObject()
  add(path_613999, "part_id", newJString(partId))
  add(path_613999, "restapi_id", newJString(restapiId))
  result = call_613998.call(path_613999, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_613985(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_613986, base: "/",
    url: url_GetDocumentationPart_613987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_614015 = ref object of OpenApiRestCall_612642
proc url_UpdateDocumentationPart_614017(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "part_id" in path, "`part_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts/"),
               (kind: VariableSegment, value: "part_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocumentationPart_614016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   part_id: JString (required)
  ##          : [Required] The identifier of the to-be-updated documentation part.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `part_id` field"
  var valid_614018 = path.getOrDefault("part_id")
  valid_614018 = validateParameter(valid_614018, JString, required = true,
                                 default = nil)
  if valid_614018 != nil:
    section.add "part_id", valid_614018
  var valid_614019 = path.getOrDefault("restapi_id")
  valid_614019 = validateParameter(valid_614019, JString, required = true,
                                 default = nil)
  if valid_614019 != nil:
    section.add "restapi_id", valid_614019
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
  var valid_614020 = header.getOrDefault("X-Amz-Signature")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-Signature", valid_614020
  var valid_614021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "X-Amz-Content-Sha256", valid_614021
  var valid_614022 = header.getOrDefault("X-Amz-Date")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Date", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Credential")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Credential", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Security-Token")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Security-Token", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Algorithm")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Algorithm", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-SignedHeaders", valid_614026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614028: Call_UpdateDocumentationPart_614015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614028.validator(path, query, header, formData, body)
  let scheme = call_614028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614028.url(scheme.get, call_614028.host, call_614028.base,
                         call_614028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614028, url, valid)

proc call*(call_614029: Call_UpdateDocumentationPart_614015; partId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_614030 = newJObject()
  var body_614031 = newJObject()
  add(path_614030, "part_id", newJString(partId))
  add(path_614030, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614031 = body
  result = call_614029.call(path_614030, nil, nil, nil, body_614031)

var updateDocumentationPart* = Call_UpdateDocumentationPart_614015(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_614016, base: "/",
    url: url_UpdateDocumentationPart_614017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_614000 = ref object of OpenApiRestCall_612642
proc url_DeleteDocumentationPart_614002(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "part_id" in path, "`part_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts/"),
               (kind: VariableSegment, value: "part_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDocumentationPart_614001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   part_id: JString (required)
  ##          : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `part_id` field"
  var valid_614003 = path.getOrDefault("part_id")
  valid_614003 = validateParameter(valid_614003, JString, required = true,
                                 default = nil)
  if valid_614003 != nil:
    section.add "part_id", valid_614003
  var valid_614004 = path.getOrDefault("restapi_id")
  valid_614004 = validateParameter(valid_614004, JString, required = true,
                                 default = nil)
  if valid_614004 != nil:
    section.add "restapi_id", valid_614004
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
  var valid_614005 = header.getOrDefault("X-Amz-Signature")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Signature", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Content-Sha256", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Date")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Date", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Credential")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Credential", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Security-Token")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Security-Token", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Algorithm")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Algorithm", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-SignedHeaders", valid_614011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614012: Call_DeleteDocumentationPart_614000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614012.validator(path, query, header, formData, body)
  let scheme = call_614012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614012.url(scheme.get, call_614012.host, call_614012.base,
                         call_614012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614012, url, valid)

proc call*(call_614013: Call_DeleteDocumentationPart_614000; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614014 = newJObject()
  add(path_614014, "part_id", newJString(partId))
  add(path_614014, "restapi_id", newJString(restapiId))
  result = call_614013.call(path_614014, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_614000(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_614001, base: "/",
    url: url_DeleteDocumentationPart_614002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_614032 = ref object of OpenApiRestCall_612642
proc url_GetDocumentationVersion_614034(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "doc_version" in path, "`doc_version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/versions/"),
               (kind: VariableSegment, value: "doc_version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationVersion_614033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   doc_version: JString (required)
  ##              : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `doc_version` field"
  var valid_614035 = path.getOrDefault("doc_version")
  valid_614035 = validateParameter(valid_614035, JString, required = true,
                                 default = nil)
  if valid_614035 != nil:
    section.add "doc_version", valid_614035
  var valid_614036 = path.getOrDefault("restapi_id")
  valid_614036 = validateParameter(valid_614036, JString, required = true,
                                 default = nil)
  if valid_614036 != nil:
    section.add "restapi_id", valid_614036
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
  var valid_614037 = header.getOrDefault("X-Amz-Signature")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "X-Amz-Signature", valid_614037
  var valid_614038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Content-Sha256", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Date")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Date", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Credential")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Credential", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Security-Token")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Security-Token", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Algorithm")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Algorithm", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-SignedHeaders", valid_614043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614044: Call_GetDocumentationVersion_614032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614044.validator(path, query, header, formData, body)
  let scheme = call_614044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614044.url(scheme.get, call_614044.host, call_614044.base,
                         call_614044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614044, url, valid)

proc call*(call_614045: Call_GetDocumentationVersion_614032; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614046 = newJObject()
  add(path_614046, "doc_version", newJString(docVersion))
  add(path_614046, "restapi_id", newJString(restapiId))
  result = call_614045.call(path_614046, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_614032(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_614033, base: "/",
    url: url_GetDocumentationVersion_614034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_614062 = ref object of OpenApiRestCall_612642
proc url_UpdateDocumentationVersion_614064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "doc_version" in path, "`doc_version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/versions/"),
               (kind: VariableSegment, value: "doc_version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocumentationVersion_614063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   doc_version: JString (required)
  ##              : [Required] The version identifier of the to-be-updated documentation version.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>..
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `doc_version` field"
  var valid_614065 = path.getOrDefault("doc_version")
  valid_614065 = validateParameter(valid_614065, JString, required = true,
                                 default = nil)
  if valid_614065 != nil:
    section.add "doc_version", valid_614065
  var valid_614066 = path.getOrDefault("restapi_id")
  valid_614066 = validateParameter(valid_614066, JString, required = true,
                                 default = nil)
  if valid_614066 != nil:
    section.add "restapi_id", valid_614066
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
  var valid_614067 = header.getOrDefault("X-Amz-Signature")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Signature", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Content-Sha256", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Date")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Date", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Credential")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Credential", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-Security-Token")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Security-Token", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-Algorithm")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-Algorithm", valid_614072
  var valid_614073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "X-Amz-SignedHeaders", valid_614073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614075: Call_UpdateDocumentationVersion_614062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614075.validator(path, query, header, formData, body)
  let scheme = call_614075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614075.url(scheme.get, call_614075.host, call_614075.base,
                         call_614075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614075, url, valid)

proc call*(call_614076: Call_UpdateDocumentationVersion_614062; docVersion: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  ##   body: JObject (required)
  var path_614077 = newJObject()
  var body_614078 = newJObject()
  add(path_614077, "doc_version", newJString(docVersion))
  add(path_614077, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614078 = body
  result = call_614076.call(path_614077, nil, nil, nil, body_614078)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_614062(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_614063, base: "/",
    url: url_UpdateDocumentationVersion_614064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_614047 = ref object of OpenApiRestCall_612642
proc url_DeleteDocumentationVersion_614049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "doc_version" in path, "`doc_version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/versions/"),
               (kind: VariableSegment, value: "doc_version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDocumentationVersion_614048(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   doc_version: JString (required)
  ##              : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `doc_version` field"
  var valid_614050 = path.getOrDefault("doc_version")
  valid_614050 = validateParameter(valid_614050, JString, required = true,
                                 default = nil)
  if valid_614050 != nil:
    section.add "doc_version", valid_614050
  var valid_614051 = path.getOrDefault("restapi_id")
  valid_614051 = validateParameter(valid_614051, JString, required = true,
                                 default = nil)
  if valid_614051 != nil:
    section.add "restapi_id", valid_614051
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
  var valid_614052 = header.getOrDefault("X-Amz-Signature")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Signature", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Content-Sha256", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Date")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Date", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Credential")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Credential", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Security-Token")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Security-Token", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Algorithm")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Algorithm", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-SignedHeaders", valid_614058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614059: Call_DeleteDocumentationVersion_614047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614059.validator(path, query, header, formData, body)
  let scheme = call_614059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614059.url(scheme.get, call_614059.host, call_614059.base,
                         call_614059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614059, url, valid)

proc call*(call_614060: Call_DeleteDocumentationVersion_614047; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614061 = newJObject()
  add(path_614061, "doc_version", newJString(docVersion))
  add(path_614061, "restapi_id", newJString(restapiId))
  result = call_614060.call(path_614061, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_614047(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_614048, base: "/",
    url: url_DeleteDocumentationVersion_614049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_614079 = ref object of OpenApiRestCall_612642
proc url_GetDomainName_614081(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainName_614080(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domain_name: JString (required)
  ##              : [Required] The name of the <a>DomainName</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domain_name` field"
  var valid_614082 = path.getOrDefault("domain_name")
  valid_614082 = validateParameter(valid_614082, JString, required = true,
                                 default = nil)
  if valid_614082 != nil:
    section.add "domain_name", valid_614082
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
  var valid_614083 = header.getOrDefault("X-Amz-Signature")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "X-Amz-Signature", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-Content-Sha256", valid_614084
  var valid_614085 = header.getOrDefault("X-Amz-Date")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-Date", valid_614085
  var valid_614086 = header.getOrDefault("X-Amz-Credential")
  valid_614086 = validateParameter(valid_614086, JString, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "X-Amz-Credential", valid_614086
  var valid_614087 = header.getOrDefault("X-Amz-Security-Token")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Security-Token", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Algorithm")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Algorithm", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-SignedHeaders", valid_614089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614090: Call_GetDomainName_614079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_614090.validator(path, query, header, formData, body)
  let scheme = call_614090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614090.url(scheme.get, call_614090.host, call_614090.base,
                         call_614090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614090, url, valid)

proc call*(call_614091: Call_GetDomainName_614079; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_614092 = newJObject()
  add(path_614092, "domain_name", newJString(domainName))
  result = call_614091.call(path_614092, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_614079(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_614080,
    base: "/", url: url_GetDomainName_614081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_614107 = ref object of OpenApiRestCall_612642
proc url_UpdateDomainName_614109(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainName_614108(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domain_name: JString (required)
  ##              : [Required] The name of the <a>DomainName</a> resource to be changed.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domain_name` field"
  var valid_614110 = path.getOrDefault("domain_name")
  valid_614110 = validateParameter(valid_614110, JString, required = true,
                                 default = nil)
  if valid_614110 != nil:
    section.add "domain_name", valid_614110
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
  var valid_614111 = header.getOrDefault("X-Amz-Signature")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "X-Amz-Signature", valid_614111
  var valid_614112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Content-Sha256", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Date")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Date", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Credential")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Credential", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Security-Token")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Security-Token", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Algorithm")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Algorithm", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-SignedHeaders", valid_614117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614119: Call_UpdateDomainName_614107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_614119.validator(path, query, header, formData, body)
  let scheme = call_614119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614119.url(scheme.get, call_614119.host, call_614119.base,
                         call_614119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614119, url, valid)

proc call*(call_614120: Call_UpdateDomainName_614107; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  var path_614121 = newJObject()
  var body_614122 = newJObject()
  if body != nil:
    body_614122 = body
  add(path_614121, "domain_name", newJString(domainName))
  result = call_614120.call(path_614121, nil, nil, nil, body_614122)

var updateDomainName* = Call_UpdateDomainName_614107(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_614108,
    base: "/", url: url_UpdateDomainName_614109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_614093 = ref object of OpenApiRestCall_612642
proc url_DeleteDomainName_614095(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainName_614094(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domain_name: JString (required)
  ##              : [Required] The name of the <a>DomainName</a> resource to be deleted.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domain_name` field"
  var valid_614096 = path.getOrDefault("domain_name")
  valid_614096 = validateParameter(valid_614096, JString, required = true,
                                 default = nil)
  if valid_614096 != nil:
    section.add "domain_name", valid_614096
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
  var valid_614097 = header.getOrDefault("X-Amz-Signature")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Signature", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Content-Sha256", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Date")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Date", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-Credential")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-Credential", valid_614100
  var valid_614101 = header.getOrDefault("X-Amz-Security-Token")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-Security-Token", valid_614101
  var valid_614102 = header.getOrDefault("X-Amz-Algorithm")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Algorithm", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-SignedHeaders", valid_614103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614104: Call_DeleteDomainName_614093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_614104.validator(path, query, header, formData, body)
  let scheme = call_614104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614104.url(scheme.get, call_614104.host, call_614104.base,
                         call_614104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614104, url, valid)

proc call*(call_614105: Call_DeleteDomainName_614093; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_614106 = newJObject()
  add(path_614106, "domain_name", newJString(domainName))
  result = call_614105.call(path_614106, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_614093(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_614094,
    base: "/", url: url_DeleteDomainName_614095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_614138 = ref object of OpenApiRestCall_612642
proc url_PutGatewayResponse_614140(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "response_type" in path, "`response_type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/gatewayresponses/"),
               (kind: VariableSegment, value: "response_type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutGatewayResponse_614139(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   response_type: JString (required)
  ##                : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  var valid_614141 = path.getOrDefault("response_type")
  valid_614141 = validateParameter(valid_614141, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_614141 != nil:
    section.add "response_type", valid_614141
  var valid_614142 = path.getOrDefault("restapi_id")
  valid_614142 = validateParameter(valid_614142, JString, required = true,
                                 default = nil)
  if valid_614142 != nil:
    section.add "restapi_id", valid_614142
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
  var valid_614143 = header.getOrDefault("X-Amz-Signature")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Signature", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Content-Sha256", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Date")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Date", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Credential")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Credential", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Security-Token")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Security-Token", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Algorithm")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Algorithm", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-SignedHeaders", valid_614149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614151: Call_PutGatewayResponse_614138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_614151.validator(path, query, header, formData, body)
  let scheme = call_614151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614151.url(scheme.get, call_614151.host, call_614151.base,
                         call_614151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614151, url, valid)

proc call*(call_614152: Call_PutGatewayResponse_614138; restapiId: string;
          body: JsonNode; responseType: string = "DEFAULT_4XX"): Recallable =
  ## putGatewayResponse
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ##   responseType: string (required)
  ##               : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_614153 = newJObject()
  var body_614154 = newJObject()
  add(path_614153, "response_type", newJString(responseType))
  add(path_614153, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614154 = body
  result = call_614152.call(path_614153, nil, nil, nil, body_614154)

var putGatewayResponse* = Call_PutGatewayResponse_614138(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_614139, base: "/",
    url: url_PutGatewayResponse_614140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_614123 = ref object of OpenApiRestCall_612642
proc url_GetGatewayResponse_614125(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "response_type" in path, "`response_type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/gatewayresponses/"),
               (kind: VariableSegment, value: "response_type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGatewayResponse_614124(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   response_type: JString (required)
  ##                : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  var valid_614126 = path.getOrDefault("response_type")
  valid_614126 = validateParameter(valid_614126, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_614126 != nil:
    section.add "response_type", valid_614126
  var valid_614127 = path.getOrDefault("restapi_id")
  valid_614127 = validateParameter(valid_614127, JString, required = true,
                                 default = nil)
  if valid_614127 != nil:
    section.add "restapi_id", valid_614127
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
  var valid_614128 = header.getOrDefault("X-Amz-Signature")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Signature", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Content-Sha256", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Date")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Date", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Credential")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Credential", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Security-Token")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Security-Token", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Algorithm")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Algorithm", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-SignedHeaders", valid_614134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614135: Call_GetGatewayResponse_614123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_614135.validator(path, query, header, formData, body)
  let scheme = call_614135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614135.url(scheme.get, call_614135.host, call_614135.base,
                         call_614135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614135, url, valid)

proc call*(call_614136: Call_GetGatewayResponse_614123; restapiId: string;
          responseType: string = "DEFAULT_4XX"): Recallable =
  ## getGatewayResponse
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ##   responseType: string (required)
  ##               : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614137 = newJObject()
  add(path_614137, "response_type", newJString(responseType))
  add(path_614137, "restapi_id", newJString(restapiId))
  result = call_614136.call(path_614137, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_614123(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_614124, base: "/",
    url: url_GetGatewayResponse_614125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_614170 = ref object of OpenApiRestCall_612642
proc url_UpdateGatewayResponse_614172(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "response_type" in path, "`response_type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/gatewayresponses/"),
               (kind: VariableSegment, value: "response_type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGatewayResponse_614171(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   response_type: JString (required)
  ##                : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  var valid_614173 = path.getOrDefault("response_type")
  valid_614173 = validateParameter(valid_614173, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_614173 != nil:
    section.add "response_type", valid_614173
  var valid_614174 = path.getOrDefault("restapi_id")
  valid_614174 = validateParameter(valid_614174, JString, required = true,
                                 default = nil)
  if valid_614174 != nil:
    section.add "restapi_id", valid_614174
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
  var valid_614175 = header.getOrDefault("X-Amz-Signature")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "X-Amz-Signature", valid_614175
  var valid_614176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-Content-Sha256", valid_614176
  var valid_614177 = header.getOrDefault("X-Amz-Date")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Date", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Credential")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Credential", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Security-Token")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Security-Token", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Algorithm")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Algorithm", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-SignedHeaders", valid_614181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614183: Call_UpdateGatewayResponse_614170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_614183.validator(path, query, header, formData, body)
  let scheme = call_614183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614183.url(scheme.get, call_614183.host, call_614183.base,
                         call_614183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614183, url, valid)

proc call*(call_614184: Call_UpdateGatewayResponse_614170; restapiId: string;
          body: JsonNode; responseType: string = "DEFAULT_4XX"): Recallable =
  ## updateGatewayResponse
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ##   responseType: string (required)
  ##               : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_614185 = newJObject()
  var body_614186 = newJObject()
  add(path_614185, "response_type", newJString(responseType))
  add(path_614185, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614186 = body
  result = call_614184.call(path_614185, nil, nil, nil, body_614186)

var updateGatewayResponse* = Call_UpdateGatewayResponse_614170(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_614171, base: "/",
    url: url_UpdateGatewayResponse_614172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_614155 = ref object of OpenApiRestCall_612642
proc url_DeleteGatewayResponse_614157(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "response_type" in path, "`response_type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/gatewayresponses/"),
               (kind: VariableSegment, value: "response_type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGatewayResponse_614156(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   response_type: JString (required)
  ##                : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  var valid_614158 = path.getOrDefault("response_type")
  valid_614158 = validateParameter(valid_614158, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_614158 != nil:
    section.add "response_type", valid_614158
  var valid_614159 = path.getOrDefault("restapi_id")
  valid_614159 = validateParameter(valid_614159, JString, required = true,
                                 default = nil)
  if valid_614159 != nil:
    section.add "restapi_id", valid_614159
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
  var valid_614160 = header.getOrDefault("X-Amz-Signature")
  valid_614160 = validateParameter(valid_614160, JString, required = false,
                                 default = nil)
  if valid_614160 != nil:
    section.add "X-Amz-Signature", valid_614160
  var valid_614161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "X-Amz-Content-Sha256", valid_614161
  var valid_614162 = header.getOrDefault("X-Amz-Date")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Date", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Credential")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Credential", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Security-Token")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Security-Token", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Algorithm")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Algorithm", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-SignedHeaders", valid_614166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614167: Call_DeleteGatewayResponse_614155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_614167.validator(path, query, header, formData, body)
  let scheme = call_614167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614167.url(scheme.get, call_614167.host, call_614167.base,
                         call_614167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614167, url, valid)

proc call*(call_614168: Call_DeleteGatewayResponse_614155; restapiId: string;
          responseType: string = "DEFAULT_4XX"): Recallable =
  ## deleteGatewayResponse
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ##   responseType: string (required)
  ##               : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614169 = newJObject()
  add(path_614169, "response_type", newJString(responseType))
  add(path_614169, "restapi_id", newJString(restapiId))
  result = call_614168.call(path_614169, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_614155(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_614156, base: "/",
    url: url_DeleteGatewayResponse_614157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_614203 = ref object of OpenApiRestCall_612642
proc url_PutIntegration_614205(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutIntegration_614204(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Sets up a method's integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a put integration request's resource ID.
  ##   http_method: JString (required)
  ##              : [Required] Specifies a put integration request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614206 = path.getOrDefault("restapi_id")
  valid_614206 = validateParameter(valid_614206, JString, required = true,
                                 default = nil)
  if valid_614206 != nil:
    section.add "restapi_id", valid_614206
  var valid_614207 = path.getOrDefault("resource_id")
  valid_614207 = validateParameter(valid_614207, JString, required = true,
                                 default = nil)
  if valid_614207 != nil:
    section.add "resource_id", valid_614207
  var valid_614208 = path.getOrDefault("http_method")
  valid_614208 = validateParameter(valid_614208, JString, required = true,
                                 default = nil)
  if valid_614208 != nil:
    section.add "http_method", valid_614208
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
  var valid_614209 = header.getOrDefault("X-Amz-Signature")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Signature", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Content-Sha256", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Date")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Date", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Credential")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Credential", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Security-Token")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Security-Token", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Algorithm")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Algorithm", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-SignedHeaders", valid_614215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614217: Call_PutIntegration_614203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_614217.validator(path, query, header, formData, body)
  let scheme = call_614217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614217.url(scheme.get, call_614217.host, call_614217.base,
                         call_614217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614217, url, valid)

proc call*(call_614218: Call_PutIntegration_614203; restapiId: string;
          body: JsonNode; resourceId: string; httpMethod: string): Recallable =
  ## putIntegration
  ## Sets up a method's integration.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] Specifies a put integration request's resource ID.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a put integration request's HTTP method.
  var path_614219 = newJObject()
  var body_614220 = newJObject()
  add(path_614219, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614220 = body
  add(path_614219, "resource_id", newJString(resourceId))
  add(path_614219, "http_method", newJString(httpMethod))
  result = call_614218.call(path_614219, nil, nil, nil, body_614220)

var putIntegration* = Call_PutIntegration_614203(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_614204, base: "/", url: url_PutIntegration_614205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_614187 = ref object of OpenApiRestCall_612642
proc url_GetIntegration_614189(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegration_614188(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Get the integration settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a get integration request's resource identifier
  ##   http_method: JString (required)
  ##              : [Required] Specifies a get integration request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614190 = path.getOrDefault("restapi_id")
  valid_614190 = validateParameter(valid_614190, JString, required = true,
                                 default = nil)
  if valid_614190 != nil:
    section.add "restapi_id", valid_614190
  var valid_614191 = path.getOrDefault("resource_id")
  valid_614191 = validateParameter(valid_614191, JString, required = true,
                                 default = nil)
  if valid_614191 != nil:
    section.add "resource_id", valid_614191
  var valid_614192 = path.getOrDefault("http_method")
  valid_614192 = validateParameter(valid_614192, JString, required = true,
                                 default = nil)
  if valid_614192 != nil:
    section.add "http_method", valid_614192
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
  var valid_614193 = header.getOrDefault("X-Amz-Signature")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "X-Amz-Signature", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Content-Sha256", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Date")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Date", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-Credential")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-Credential", valid_614196
  var valid_614197 = header.getOrDefault("X-Amz-Security-Token")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Security-Token", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Algorithm")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Algorithm", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-SignedHeaders", valid_614199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614200: Call_GetIntegration_614187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_614200.validator(path, query, header, formData, body)
  let scheme = call_614200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614200.url(scheme.get, call_614200.host, call_614200.base,
                         call_614200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614200, url, valid)

proc call*(call_614201: Call_GetIntegration_614187; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  var path_614202 = newJObject()
  add(path_614202, "restapi_id", newJString(restapiId))
  add(path_614202, "resource_id", newJString(resourceId))
  add(path_614202, "http_method", newJString(httpMethod))
  result = call_614201.call(path_614202, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_614187(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_614188, base: "/", url: url_GetIntegration_614189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_614237 = ref object of OpenApiRestCall_612642
proc url_UpdateIntegration_614239(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegration_614238(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Represents an update integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Represents an update integration request's resource identifier.
  ##   http_method: JString (required)
  ##              : [Required] Represents an update integration request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614240 = path.getOrDefault("restapi_id")
  valid_614240 = validateParameter(valid_614240, JString, required = true,
                                 default = nil)
  if valid_614240 != nil:
    section.add "restapi_id", valid_614240
  var valid_614241 = path.getOrDefault("resource_id")
  valid_614241 = validateParameter(valid_614241, JString, required = true,
                                 default = nil)
  if valid_614241 != nil:
    section.add "resource_id", valid_614241
  var valid_614242 = path.getOrDefault("http_method")
  valid_614242 = validateParameter(valid_614242, JString, required = true,
                                 default = nil)
  if valid_614242 != nil:
    section.add "http_method", valid_614242
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
  var valid_614243 = header.getOrDefault("X-Amz-Signature")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-Signature", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Content-Sha256", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Date")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Date", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Credential")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Credential", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-Security-Token")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-Security-Token", valid_614247
  var valid_614248 = header.getOrDefault("X-Amz-Algorithm")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "X-Amz-Algorithm", valid_614248
  var valid_614249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-SignedHeaders", valid_614249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614251: Call_UpdateIntegration_614237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_614251.validator(path, query, header, formData, body)
  let scheme = call_614251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614251.url(scheme.get, call_614251.host, call_614251.base,
                         call_614251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614251, url, valid)

proc call*(call_614252: Call_UpdateIntegration_614237; restapiId: string;
          body: JsonNode; resourceId: string; httpMethod: string): Recallable =
  ## updateIntegration
  ## Represents an update integration.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] Represents an update integration request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Represents an update integration request's HTTP method.
  var path_614253 = newJObject()
  var body_614254 = newJObject()
  add(path_614253, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614254 = body
  add(path_614253, "resource_id", newJString(resourceId))
  add(path_614253, "http_method", newJString(httpMethod))
  result = call_614252.call(path_614253, nil, nil, nil, body_614254)

var updateIntegration* = Call_UpdateIntegration_614237(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_614238, base: "/",
    url: url_UpdateIntegration_614239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_614221 = ref object of OpenApiRestCall_612642
proc url_DeleteIntegration_614223(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegration_614222(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Represents a delete integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a delete integration request's resource identifier.
  ##   http_method: JString (required)
  ##              : [Required] Specifies a delete integration request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614224 = path.getOrDefault("restapi_id")
  valid_614224 = validateParameter(valid_614224, JString, required = true,
                                 default = nil)
  if valid_614224 != nil:
    section.add "restapi_id", valid_614224
  var valid_614225 = path.getOrDefault("resource_id")
  valid_614225 = validateParameter(valid_614225, JString, required = true,
                                 default = nil)
  if valid_614225 != nil:
    section.add "resource_id", valid_614225
  var valid_614226 = path.getOrDefault("http_method")
  valid_614226 = validateParameter(valid_614226, JString, required = true,
                                 default = nil)
  if valid_614226 != nil:
    section.add "http_method", valid_614226
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
  if body != nil:
    result.add "body", body

proc call*(call_614234: Call_DeleteIntegration_614221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_614234.validator(path, query, header, formData, body)
  let scheme = call_614234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614234.url(scheme.get, call_614234.host, call_614234.base,
                         call_614234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614234, url, valid)

proc call*(call_614235: Call_DeleteIntegration_614221; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  var path_614236 = newJObject()
  add(path_614236, "restapi_id", newJString(restapiId))
  add(path_614236, "resource_id", newJString(resourceId))
  add(path_614236, "http_method", newJString(httpMethod))
  result = call_614235.call(path_614236, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_614221(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_614222, base: "/",
    url: url_DeleteIntegration_614223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_614272 = ref object of OpenApiRestCall_612642
proc url_PutIntegrationResponse_614274(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutIntegrationResponse_614273(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents a put integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a put integration response request's resource identifier.
  ##   http_method: JString (required)
  ##              : [Required] Specifies a put integration response request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614275 = path.getOrDefault("status_code")
  valid_614275 = validateParameter(valid_614275, JString, required = true,
                                 default = nil)
  if valid_614275 != nil:
    section.add "status_code", valid_614275
  var valid_614276 = path.getOrDefault("restapi_id")
  valid_614276 = validateParameter(valid_614276, JString, required = true,
                                 default = nil)
  if valid_614276 != nil:
    section.add "restapi_id", valid_614276
  var valid_614277 = path.getOrDefault("resource_id")
  valid_614277 = validateParameter(valid_614277, JString, required = true,
                                 default = nil)
  if valid_614277 != nil:
    section.add "resource_id", valid_614277
  var valid_614278 = path.getOrDefault("http_method")
  valid_614278 = validateParameter(valid_614278, JString, required = true,
                                 default = nil)
  if valid_614278 != nil:
    section.add "http_method", valid_614278
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
  var valid_614279 = header.getOrDefault("X-Amz-Signature")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Signature", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-Content-Sha256", valid_614280
  var valid_614281 = header.getOrDefault("X-Amz-Date")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "X-Amz-Date", valid_614281
  var valid_614282 = header.getOrDefault("X-Amz-Credential")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "X-Amz-Credential", valid_614282
  var valid_614283 = header.getOrDefault("X-Amz-Security-Token")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Security-Token", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Algorithm")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Algorithm", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-SignedHeaders", valid_614285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614287: Call_PutIntegrationResponse_614272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_614287.validator(path, query, header, formData, body)
  let scheme = call_614287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614287.url(scheme.get, call_614287.host, call_614287.base,
                         call_614287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614287, url, valid)

proc call*(call_614288: Call_PutIntegrationResponse_614272; statusCode: string;
          restapiId: string; body: JsonNode; resourceId: string; httpMethod: string): Recallable =
  ## putIntegrationResponse
  ## Represents a put integration.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] Specifies a put integration response request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a put integration response request's HTTP method.
  var path_614289 = newJObject()
  var body_614290 = newJObject()
  add(path_614289, "status_code", newJString(statusCode))
  add(path_614289, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614290 = body
  add(path_614289, "resource_id", newJString(resourceId))
  add(path_614289, "http_method", newJString(httpMethod))
  result = call_614288.call(path_614289, nil, nil, nil, body_614290)

var putIntegrationResponse* = Call_PutIntegrationResponse_614272(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_614273, base: "/",
    url: url_PutIntegrationResponse_614274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_614255 = ref object of OpenApiRestCall_612642
proc url_GetIntegrationResponse_614257(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponse_614256(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents a get integration response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a get integration response request's resource identifier.
  ##   http_method: JString (required)
  ##              : [Required] Specifies a get integration response request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614258 = path.getOrDefault("status_code")
  valid_614258 = validateParameter(valid_614258, JString, required = true,
                                 default = nil)
  if valid_614258 != nil:
    section.add "status_code", valid_614258
  var valid_614259 = path.getOrDefault("restapi_id")
  valid_614259 = validateParameter(valid_614259, JString, required = true,
                                 default = nil)
  if valid_614259 != nil:
    section.add "restapi_id", valid_614259
  var valid_614260 = path.getOrDefault("resource_id")
  valid_614260 = validateParameter(valid_614260, JString, required = true,
                                 default = nil)
  if valid_614260 != nil:
    section.add "resource_id", valid_614260
  var valid_614261 = path.getOrDefault("http_method")
  valid_614261 = validateParameter(valid_614261, JString, required = true,
                                 default = nil)
  if valid_614261 != nil:
    section.add "http_method", valid_614261
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
  var valid_614262 = header.getOrDefault("X-Amz-Signature")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-Signature", valid_614262
  var valid_614263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "X-Amz-Content-Sha256", valid_614263
  var valid_614264 = header.getOrDefault("X-Amz-Date")
  valid_614264 = validateParameter(valid_614264, JString, required = false,
                                 default = nil)
  if valid_614264 != nil:
    section.add "X-Amz-Date", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-Credential")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-Credential", valid_614265
  var valid_614266 = header.getOrDefault("X-Amz-Security-Token")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Security-Token", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Algorithm")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Algorithm", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-SignedHeaders", valid_614268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614269: Call_GetIntegrationResponse_614255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_614269.validator(path, query, header, formData, body)
  let scheme = call_614269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614269.url(scheme.get, call_614269.host, call_614269.base,
                         call_614269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614269, url, valid)

proc call*(call_614270: Call_GetIntegrationResponse_614255; statusCode: string;
          restapiId: string; resourceId: string; httpMethod: string): Recallable =
  ## getIntegrationResponse
  ## Represents a get integration response.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration response request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration response request's HTTP method.
  var path_614271 = newJObject()
  add(path_614271, "status_code", newJString(statusCode))
  add(path_614271, "restapi_id", newJString(restapiId))
  add(path_614271, "resource_id", newJString(resourceId))
  add(path_614271, "http_method", newJString(httpMethod))
  result = call_614270.call(path_614271, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_614255(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_614256, base: "/",
    url: url_GetIntegrationResponse_614257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_614308 = ref object of OpenApiRestCall_612642
proc url_UpdateIntegrationResponse_614310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_614309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents an update integration response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies an update integration response request's resource identifier.
  ##   http_method: JString (required)
  ##              : [Required] Specifies an update integration response request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614311 = path.getOrDefault("status_code")
  valid_614311 = validateParameter(valid_614311, JString, required = true,
                                 default = nil)
  if valid_614311 != nil:
    section.add "status_code", valid_614311
  var valid_614312 = path.getOrDefault("restapi_id")
  valid_614312 = validateParameter(valid_614312, JString, required = true,
                                 default = nil)
  if valid_614312 != nil:
    section.add "restapi_id", valid_614312
  var valid_614313 = path.getOrDefault("resource_id")
  valid_614313 = validateParameter(valid_614313, JString, required = true,
                                 default = nil)
  if valid_614313 != nil:
    section.add "resource_id", valid_614313
  var valid_614314 = path.getOrDefault("http_method")
  valid_614314 = validateParameter(valid_614314, JString, required = true,
                                 default = nil)
  if valid_614314 != nil:
    section.add "http_method", valid_614314
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
  var valid_614315 = header.getOrDefault("X-Amz-Signature")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-Signature", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Content-Sha256", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Date")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Date", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Credential")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Credential", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Security-Token")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Security-Token", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Algorithm")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Algorithm", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-SignedHeaders", valid_614321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614323: Call_UpdateIntegrationResponse_614308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_614323.validator(path, query, header, formData, body)
  let scheme = call_614323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614323.url(scheme.get, call_614323.host, call_614323.base,
                         call_614323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614323, url, valid)

proc call*(call_614324: Call_UpdateIntegrationResponse_614308; statusCode: string;
          restapiId: string; body: JsonNode; resourceId: string; httpMethod: string): Recallable =
  ## updateIntegrationResponse
  ## Represents an update integration response.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] Specifies an update integration response request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies an update integration response request's HTTP method.
  var path_614325 = newJObject()
  var body_614326 = newJObject()
  add(path_614325, "status_code", newJString(statusCode))
  add(path_614325, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614326 = body
  add(path_614325, "resource_id", newJString(resourceId))
  add(path_614325, "http_method", newJString(httpMethod))
  result = call_614324.call(path_614325, nil, nil, nil, body_614326)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_614308(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_614309, base: "/",
    url: url_UpdateIntegrationResponse_614310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_614291 = ref object of OpenApiRestCall_612642
proc url_DeleteIntegrationResponse_614293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/integration/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_614292(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents a delete integration response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a delete integration response request's resource identifier.
  ##   http_method: JString (required)
  ##              : [Required] Specifies a delete integration response request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614294 = path.getOrDefault("status_code")
  valid_614294 = validateParameter(valid_614294, JString, required = true,
                                 default = nil)
  if valid_614294 != nil:
    section.add "status_code", valid_614294
  var valid_614295 = path.getOrDefault("restapi_id")
  valid_614295 = validateParameter(valid_614295, JString, required = true,
                                 default = nil)
  if valid_614295 != nil:
    section.add "restapi_id", valid_614295
  var valid_614296 = path.getOrDefault("resource_id")
  valid_614296 = validateParameter(valid_614296, JString, required = true,
                                 default = nil)
  if valid_614296 != nil:
    section.add "resource_id", valid_614296
  var valid_614297 = path.getOrDefault("http_method")
  valid_614297 = validateParameter(valid_614297, JString, required = true,
                                 default = nil)
  if valid_614297 != nil:
    section.add "http_method", valid_614297
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
  var valid_614298 = header.getOrDefault("X-Amz-Signature")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-Signature", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Content-Sha256", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-Date")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Date", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Credential")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Credential", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Security-Token")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Security-Token", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Algorithm")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Algorithm", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-SignedHeaders", valid_614304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614305: Call_DeleteIntegrationResponse_614291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_614305.validator(path, query, header, formData, body)
  let scheme = call_614305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614305.url(scheme.get, call_614305.host, call_614305.base,
                         call_614305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614305, url, valid)

proc call*(call_614306: Call_DeleteIntegrationResponse_614291; statusCode: string;
          restapiId: string; resourceId: string; httpMethod: string): Recallable =
  ## deleteIntegrationResponse
  ## Represents a delete integration response.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration response request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration response request's HTTP method.
  var path_614307 = newJObject()
  add(path_614307, "status_code", newJString(statusCode))
  add(path_614307, "restapi_id", newJString(restapiId))
  add(path_614307, "resource_id", newJString(resourceId))
  add(path_614307, "http_method", newJString(httpMethod))
  result = call_614306.call(path_614307, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_614291(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_614292, base: "/",
    url: url_DeleteIntegrationResponse_614293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_614343 = ref object of OpenApiRestCall_612642
proc url_PutMethod_614345(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutMethod_614344(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the new <a>Method</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] Specifies the method request's HTTP method type.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614346 = path.getOrDefault("restapi_id")
  valid_614346 = validateParameter(valid_614346, JString, required = true,
                                 default = nil)
  if valid_614346 != nil:
    section.add "restapi_id", valid_614346
  var valid_614347 = path.getOrDefault("resource_id")
  valid_614347 = validateParameter(valid_614347, JString, required = true,
                                 default = nil)
  if valid_614347 != nil:
    section.add "resource_id", valid_614347
  var valid_614348 = path.getOrDefault("http_method")
  valid_614348 = validateParameter(valid_614348, JString, required = true,
                                 default = nil)
  if valid_614348 != nil:
    section.add "http_method", valid_614348
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
  var valid_614349 = header.getOrDefault("X-Amz-Signature")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Signature", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Content-Sha256", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Date")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Date", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-Credential")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Credential", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Security-Token")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Security-Token", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Algorithm")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Algorithm", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-SignedHeaders", valid_614355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614357: Call_PutMethod_614343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_614357.validator(path, query, header, formData, body)
  let scheme = call_614357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614357.url(scheme.get, call_614357.host, call_614357.base,
                         call_614357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614357, url, valid)

proc call*(call_614358: Call_PutMethod_614343; restapiId: string; body: JsonNode;
          resourceId: string; httpMethod: string): Recallable =
  ## putMethod
  ## Add a method to an existing <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the new <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  var path_614359 = newJObject()
  var body_614360 = newJObject()
  add(path_614359, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614360 = body
  add(path_614359, "resource_id", newJString(resourceId))
  add(path_614359, "http_method", newJString(httpMethod))
  result = call_614358.call(path_614359, nil, nil, nil, body_614360)

var putMethod* = Call_PutMethod_614343(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_614344,
                                    base: "/", url: url_PutMethod_614345,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_614361 = ref object of OpenApiRestCall_612642
proc url_TestInvokeMethod_614363(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TestInvokeMethod_614362(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a test invoke method request's resource ID.
  ##   http_method: JString (required)
  ##              : [Required] Specifies a test invoke method request's HTTP method.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614364 = path.getOrDefault("restapi_id")
  valid_614364 = validateParameter(valid_614364, JString, required = true,
                                 default = nil)
  if valid_614364 != nil:
    section.add "restapi_id", valid_614364
  var valid_614365 = path.getOrDefault("resource_id")
  valid_614365 = validateParameter(valid_614365, JString, required = true,
                                 default = nil)
  if valid_614365 != nil:
    section.add "resource_id", valid_614365
  var valid_614366 = path.getOrDefault("http_method")
  valid_614366 = validateParameter(valid_614366, JString, required = true,
                                 default = nil)
  if valid_614366 != nil:
    section.add "http_method", valid_614366
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
  var valid_614367 = header.getOrDefault("X-Amz-Signature")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-Signature", valid_614367
  var valid_614368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-Content-Sha256", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Date")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Date", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-Credential")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Credential", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Security-Token")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Security-Token", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Algorithm")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Algorithm", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-SignedHeaders", valid_614373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614375: Call_TestInvokeMethod_614361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_614375.validator(path, query, header, formData, body)
  let scheme = call_614375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614375.url(scheme.get, call_614375.host, call_614375.base,
                         call_614375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614375, url, valid)

proc call*(call_614376: Call_TestInvokeMethod_614361; restapiId: string;
          body: JsonNode; resourceId: string; httpMethod: string): Recallable =
  ## testInvokeMethod
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] Specifies a test invoke method request's resource ID.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a test invoke method request's HTTP method.
  var path_614377 = newJObject()
  var body_614378 = newJObject()
  add(path_614377, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614378 = body
  add(path_614377, "resource_id", newJString(resourceId))
  add(path_614377, "http_method", newJString(httpMethod))
  result = call_614376.call(path_614377, nil, nil, nil, body_614378)

var testInvokeMethod* = Call_TestInvokeMethod_614361(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_614362, base: "/",
    url: url_TestInvokeMethod_614363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_614327 = ref object of OpenApiRestCall_612642
proc url_GetMethod_614329(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMethod_614328(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Describe an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] Specifies the method request's HTTP method type.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614330 = path.getOrDefault("restapi_id")
  valid_614330 = validateParameter(valid_614330, JString, required = true,
                                 default = nil)
  if valid_614330 != nil:
    section.add "restapi_id", valid_614330
  var valid_614331 = path.getOrDefault("resource_id")
  valid_614331 = validateParameter(valid_614331, JString, required = true,
                                 default = nil)
  if valid_614331 != nil:
    section.add "resource_id", valid_614331
  var valid_614332 = path.getOrDefault("http_method")
  valid_614332 = validateParameter(valid_614332, JString, required = true,
                                 default = nil)
  if valid_614332 != nil:
    section.add "http_method", valid_614332
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
  var valid_614333 = header.getOrDefault("X-Amz-Signature")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Signature", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Content-Sha256", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Date")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Date", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Credential")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Credential", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-Security-Token")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Security-Token", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Algorithm")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Algorithm", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-SignedHeaders", valid_614339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614340: Call_GetMethod_614327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_614340.validator(path, query, header, formData, body)
  let scheme = call_614340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614340.url(scheme.get, call_614340.host, call_614340.base,
                         call_614340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614340, url, valid)

proc call*(call_614341: Call_GetMethod_614327; restapiId: string; resourceId: string;
          httpMethod: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  var path_614342 = newJObject()
  add(path_614342, "restapi_id", newJString(restapiId))
  add(path_614342, "resource_id", newJString(resourceId))
  add(path_614342, "http_method", newJString(httpMethod))
  result = call_614341.call(path_614342, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_614327(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_614328,
                                    base: "/", url: url_GetMethod_614329,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_614395 = ref object of OpenApiRestCall_612642
proc url_UpdateMethod_614397(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMethod_614396(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614398 = path.getOrDefault("restapi_id")
  valid_614398 = validateParameter(valid_614398, JString, required = true,
                                 default = nil)
  if valid_614398 != nil:
    section.add "restapi_id", valid_614398
  var valid_614399 = path.getOrDefault("resource_id")
  valid_614399 = validateParameter(valid_614399, JString, required = true,
                                 default = nil)
  if valid_614399 != nil:
    section.add "resource_id", valid_614399
  var valid_614400 = path.getOrDefault("http_method")
  valid_614400 = validateParameter(valid_614400, JString, required = true,
                                 default = nil)
  if valid_614400 != nil:
    section.add "http_method", valid_614400
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
  var valid_614401 = header.getOrDefault("X-Amz-Signature")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "X-Amz-Signature", valid_614401
  var valid_614402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "X-Amz-Content-Sha256", valid_614402
  var valid_614403 = header.getOrDefault("X-Amz-Date")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "X-Amz-Date", valid_614403
  var valid_614404 = header.getOrDefault("X-Amz-Credential")
  valid_614404 = validateParameter(valid_614404, JString, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "X-Amz-Credential", valid_614404
  var valid_614405 = header.getOrDefault("X-Amz-Security-Token")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Security-Token", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Algorithm")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Algorithm", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-SignedHeaders", valid_614407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614409: Call_UpdateMethod_614395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_614409.validator(path, query, header, formData, body)
  let scheme = call_614409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614409.url(scheme.get, call_614409.host, call_614409.base,
                         call_614409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614409, url, valid)

proc call*(call_614410: Call_UpdateMethod_614395; restapiId: string; body: JsonNode;
          resourceId: string; httpMethod: string): Recallable =
  ## updateMethod
  ## Updates an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_614411 = newJObject()
  var body_614412 = newJObject()
  add(path_614411, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614412 = body
  add(path_614411, "resource_id", newJString(resourceId))
  add(path_614411, "http_method", newJString(httpMethod))
  result = call_614410.call(path_614411, nil, nil, nil, body_614412)

var updateMethod* = Call_UpdateMethod_614395(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_614396, base: "/", url: url_UpdateMethod_614397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_614379 = ref object of OpenApiRestCall_612642
proc url_DeleteMethod_614381(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMethod_614380(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614382 = path.getOrDefault("restapi_id")
  valid_614382 = validateParameter(valid_614382, JString, required = true,
                                 default = nil)
  if valid_614382 != nil:
    section.add "restapi_id", valid_614382
  var valid_614383 = path.getOrDefault("resource_id")
  valid_614383 = validateParameter(valid_614383, JString, required = true,
                                 default = nil)
  if valid_614383 != nil:
    section.add "resource_id", valid_614383
  var valid_614384 = path.getOrDefault("http_method")
  valid_614384 = validateParameter(valid_614384, JString, required = true,
                                 default = nil)
  if valid_614384 != nil:
    section.add "http_method", valid_614384
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
  var valid_614385 = header.getOrDefault("X-Amz-Signature")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-Signature", valid_614385
  var valid_614386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614386 = validateParameter(valid_614386, JString, required = false,
                                 default = nil)
  if valid_614386 != nil:
    section.add "X-Amz-Content-Sha256", valid_614386
  var valid_614387 = header.getOrDefault("X-Amz-Date")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "X-Amz-Date", valid_614387
  var valid_614388 = header.getOrDefault("X-Amz-Credential")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Credential", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-Security-Token")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-Security-Token", valid_614389
  var valid_614390 = header.getOrDefault("X-Amz-Algorithm")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Algorithm", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-SignedHeaders", valid_614391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614392: Call_DeleteMethod_614379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_614392.validator(path, query, header, formData, body)
  let scheme = call_614392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614392.url(scheme.get, call_614392.host, call_614392.base,
                         call_614392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614392, url, valid)

proc call*(call_614393: Call_DeleteMethod_614379; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_614394 = newJObject()
  add(path_614394, "restapi_id", newJString(restapiId))
  add(path_614394, "resource_id", newJString(resourceId))
  add(path_614394, "http_method", newJString(httpMethod))
  result = call_614393.call(path_614394, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_614379(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_614380, base: "/", url: url_DeleteMethod_614381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_614430 = ref object of OpenApiRestCall_612642
proc url_PutMethodResponse_614432(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutMethodResponse_614431(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614433 = path.getOrDefault("status_code")
  valid_614433 = validateParameter(valid_614433, JString, required = true,
                                 default = nil)
  if valid_614433 != nil:
    section.add "status_code", valid_614433
  var valid_614434 = path.getOrDefault("restapi_id")
  valid_614434 = validateParameter(valid_614434, JString, required = true,
                                 default = nil)
  if valid_614434 != nil:
    section.add "restapi_id", valid_614434
  var valid_614435 = path.getOrDefault("resource_id")
  valid_614435 = validateParameter(valid_614435, JString, required = true,
                                 default = nil)
  if valid_614435 != nil:
    section.add "resource_id", valid_614435
  var valid_614436 = path.getOrDefault("http_method")
  valid_614436 = validateParameter(valid_614436, JString, required = true,
                                 default = nil)
  if valid_614436 != nil:
    section.add "http_method", valid_614436
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
  var valid_614437 = header.getOrDefault("X-Amz-Signature")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Signature", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-Content-Sha256", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-Date")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Date", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Credential")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Credential", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Security-Token")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Security-Token", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Algorithm")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Algorithm", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-SignedHeaders", valid_614443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614445: Call_PutMethodResponse_614430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_614445.validator(path, query, header, formData, body)
  let scheme = call_614445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614445.url(scheme.get, call_614445.host, call_614445.base,
                         call_614445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614445, url, valid)

proc call*(call_614446: Call_PutMethodResponse_614430; statusCode: string;
          restapiId: string; body: JsonNode; resourceId: string; httpMethod: string): Recallable =
  ## putMethodResponse
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_614447 = newJObject()
  var body_614448 = newJObject()
  add(path_614447, "status_code", newJString(statusCode))
  add(path_614447, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614448 = body
  add(path_614447, "resource_id", newJString(resourceId))
  add(path_614447, "http_method", newJString(httpMethod))
  result = call_614446.call(path_614447, nil, nil, nil, body_614448)

var putMethodResponse* = Call_PutMethodResponse_614430(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_614431, base: "/",
    url: url_PutMethodResponse_614432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_614413 = ref object of OpenApiRestCall_612642
proc url_GetMethodResponse_614415(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMethodResponse_614414(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614416 = path.getOrDefault("status_code")
  valid_614416 = validateParameter(valid_614416, JString, required = true,
                                 default = nil)
  if valid_614416 != nil:
    section.add "status_code", valid_614416
  var valid_614417 = path.getOrDefault("restapi_id")
  valid_614417 = validateParameter(valid_614417, JString, required = true,
                                 default = nil)
  if valid_614417 != nil:
    section.add "restapi_id", valid_614417
  var valid_614418 = path.getOrDefault("resource_id")
  valid_614418 = validateParameter(valid_614418, JString, required = true,
                                 default = nil)
  if valid_614418 != nil:
    section.add "resource_id", valid_614418
  var valid_614419 = path.getOrDefault("http_method")
  valid_614419 = validateParameter(valid_614419, JString, required = true,
                                 default = nil)
  if valid_614419 != nil:
    section.add "http_method", valid_614419
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
  var valid_614420 = header.getOrDefault("X-Amz-Signature")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Signature", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Content-Sha256", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Date")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Date", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Credential")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Credential", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-Security-Token")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Security-Token", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Algorithm")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Algorithm", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-SignedHeaders", valid_614426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614427: Call_GetMethodResponse_614413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_614427.validator(path, query, header, formData, body)
  let scheme = call_614427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614427.url(scheme.get, call_614427.host, call_614427.base,
                         call_614427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614427, url, valid)

proc call*(call_614428: Call_GetMethodResponse_614413; statusCode: string;
          restapiId: string; resourceId: string; httpMethod: string): Recallable =
  ## getMethodResponse
  ## Describes a <a>MethodResponse</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_614429 = newJObject()
  add(path_614429, "status_code", newJString(statusCode))
  add(path_614429, "restapi_id", newJString(restapiId))
  add(path_614429, "resource_id", newJString(resourceId))
  add(path_614429, "http_method", newJString(httpMethod))
  result = call_614428.call(path_614429, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_614413(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_614414, base: "/",
    url: url_GetMethodResponse_614415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_614466 = ref object of OpenApiRestCall_612642
proc url_UpdateMethodResponse_614468(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMethodResponse_614467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614469 = path.getOrDefault("status_code")
  valid_614469 = validateParameter(valid_614469, JString, required = true,
                                 default = nil)
  if valid_614469 != nil:
    section.add "status_code", valid_614469
  var valid_614470 = path.getOrDefault("restapi_id")
  valid_614470 = validateParameter(valid_614470, JString, required = true,
                                 default = nil)
  if valid_614470 != nil:
    section.add "restapi_id", valid_614470
  var valid_614471 = path.getOrDefault("resource_id")
  valid_614471 = validateParameter(valid_614471, JString, required = true,
                                 default = nil)
  if valid_614471 != nil:
    section.add "resource_id", valid_614471
  var valid_614472 = path.getOrDefault("http_method")
  valid_614472 = validateParameter(valid_614472, JString, required = true,
                                 default = nil)
  if valid_614472 != nil:
    section.add "http_method", valid_614472
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
  var valid_614473 = header.getOrDefault("X-Amz-Signature")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Signature", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Content-Sha256", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-Date")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-Date", valid_614475
  var valid_614476 = header.getOrDefault("X-Amz-Credential")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "X-Amz-Credential", valid_614476
  var valid_614477 = header.getOrDefault("X-Amz-Security-Token")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "X-Amz-Security-Token", valid_614477
  var valid_614478 = header.getOrDefault("X-Amz-Algorithm")
  valid_614478 = validateParameter(valid_614478, JString, required = false,
                                 default = nil)
  if valid_614478 != nil:
    section.add "X-Amz-Algorithm", valid_614478
  var valid_614479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614479 = validateParameter(valid_614479, JString, required = false,
                                 default = nil)
  if valid_614479 != nil:
    section.add "X-Amz-SignedHeaders", valid_614479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614481: Call_UpdateMethodResponse_614466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_614481.validator(path, query, header, formData, body)
  let scheme = call_614481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614481.url(scheme.get, call_614481.host, call_614481.base,
                         call_614481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614481, url, valid)

proc call*(call_614482: Call_UpdateMethodResponse_614466; statusCode: string;
          restapiId: string; body: JsonNode; resourceId: string; httpMethod: string): Recallable =
  ## updateMethodResponse
  ## Updates an existing <a>MethodResponse</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_614483 = newJObject()
  var body_614484 = newJObject()
  add(path_614483, "status_code", newJString(statusCode))
  add(path_614483, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614484 = body
  add(path_614483, "resource_id", newJString(resourceId))
  add(path_614483, "http_method", newJString(httpMethod))
  result = call_614482.call(path_614483, nil, nil, nil, body_614484)

var updateMethodResponse* = Call_UpdateMethodResponse_614466(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_614467, base: "/",
    url: url_UpdateMethodResponse_614468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_614449 = ref object of OpenApiRestCall_612642
proc url_DeleteMethodResponse_614451(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  assert "http_method" in path, "`http_method` is a required path parameter"
  assert "status_code" in path, "`status_code` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id"),
               (kind: ConstantSegment, value: "/methods/"),
               (kind: VariableSegment, value: "http_method"),
               (kind: ConstantSegment, value: "/responses/"),
               (kind: VariableSegment, value: "status_code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMethodResponse_614450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `status_code` field"
  var valid_614452 = path.getOrDefault("status_code")
  valid_614452 = validateParameter(valid_614452, JString, required = true,
                                 default = nil)
  if valid_614452 != nil:
    section.add "status_code", valid_614452
  var valid_614453 = path.getOrDefault("restapi_id")
  valid_614453 = validateParameter(valid_614453, JString, required = true,
                                 default = nil)
  if valid_614453 != nil:
    section.add "restapi_id", valid_614453
  var valid_614454 = path.getOrDefault("resource_id")
  valid_614454 = validateParameter(valid_614454, JString, required = true,
                                 default = nil)
  if valid_614454 != nil:
    section.add "resource_id", valid_614454
  var valid_614455 = path.getOrDefault("http_method")
  valid_614455 = validateParameter(valid_614455, JString, required = true,
                                 default = nil)
  if valid_614455 != nil:
    section.add "http_method", valid_614455
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
  var valid_614456 = header.getOrDefault("X-Amz-Signature")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Signature", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Content-Sha256", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-Date")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Date", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Credential")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Credential", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-Security-Token")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-Security-Token", valid_614460
  var valid_614461 = header.getOrDefault("X-Amz-Algorithm")
  valid_614461 = validateParameter(valid_614461, JString, required = false,
                                 default = nil)
  if valid_614461 != nil:
    section.add "X-Amz-Algorithm", valid_614461
  var valid_614462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614462 = validateParameter(valid_614462, JString, required = false,
                                 default = nil)
  if valid_614462 != nil:
    section.add "X-Amz-SignedHeaders", valid_614462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614463: Call_DeleteMethodResponse_614449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_614463.validator(path, query, header, formData, body)
  let scheme = call_614463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614463.url(scheme.get, call_614463.host, call_614463.base,
                         call_614463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614463, url, valid)

proc call*(call_614464: Call_DeleteMethodResponse_614449; statusCode: string;
          restapiId: string; resourceId: string; httpMethod: string): Recallable =
  ## deleteMethodResponse
  ## Deletes an existing <a>MethodResponse</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_614465 = newJObject()
  add(path_614465, "status_code", newJString(statusCode))
  add(path_614465, "restapi_id", newJString(restapiId))
  add(path_614465, "resource_id", newJString(resourceId))
  add(path_614465, "http_method", newJString(httpMethod))
  result = call_614464.call(path_614465, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_614449(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_614450, base: "/",
    url: url_DeleteMethodResponse_614451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_614485 = ref object of OpenApiRestCall_612642
proc url_GetModel_614487(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "model_name" in path, "`model_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "model_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModel_614486(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   model_name: JString (required)
  ##             : [Required] The name of the model as an identifier.
  ##   restapi_id: JString (required)
  ##             : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `model_name` field"
  var valid_614488 = path.getOrDefault("model_name")
  valid_614488 = validateParameter(valid_614488, JString, required = true,
                                 default = nil)
  if valid_614488 != nil:
    section.add "model_name", valid_614488
  var valid_614489 = path.getOrDefault("restapi_id")
  valid_614489 = validateParameter(valid_614489, JString, required = true,
                                 default = nil)
  if valid_614489 != nil:
    section.add "restapi_id", valid_614489
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_614490 = query.getOrDefault("flatten")
  valid_614490 = validateParameter(valid_614490, JBool, required = false, default = nil)
  if valid_614490 != nil:
    section.add "flatten", valid_614490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614491 = header.getOrDefault("X-Amz-Signature")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Signature", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-Content-Sha256", valid_614492
  var valid_614493 = header.getOrDefault("X-Amz-Date")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "X-Amz-Date", valid_614493
  var valid_614494 = header.getOrDefault("X-Amz-Credential")
  valid_614494 = validateParameter(valid_614494, JString, required = false,
                                 default = nil)
  if valid_614494 != nil:
    section.add "X-Amz-Credential", valid_614494
  var valid_614495 = header.getOrDefault("X-Amz-Security-Token")
  valid_614495 = validateParameter(valid_614495, JString, required = false,
                                 default = nil)
  if valid_614495 != nil:
    section.add "X-Amz-Security-Token", valid_614495
  var valid_614496 = header.getOrDefault("X-Amz-Algorithm")
  valid_614496 = validateParameter(valid_614496, JString, required = false,
                                 default = nil)
  if valid_614496 != nil:
    section.add "X-Amz-Algorithm", valid_614496
  var valid_614497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614497 = validateParameter(valid_614497, JString, required = false,
                                 default = nil)
  if valid_614497 != nil:
    section.add "X-Amz-SignedHeaders", valid_614497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614498: Call_GetModel_614485; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_614498.validator(path, query, header, formData, body)
  let scheme = call_614498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614498.url(scheme.get, call_614498.host, call_614498.base,
                         call_614498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614498, url, valid)

proc call*(call_614499: Call_GetModel_614485; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_614500 = newJObject()
  var query_614501 = newJObject()
  add(query_614501, "flatten", newJBool(flatten))
  add(path_614500, "model_name", newJString(modelName))
  add(path_614500, "restapi_id", newJString(restapiId))
  result = call_614499.call(path_614500, query_614501, nil, nil, nil)

var getModel* = Call_GetModel_614485(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_614486, base: "/",
                                  url: url_GetModel_614487,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_614517 = ref object of OpenApiRestCall_612642
proc url_UpdateModel_614519(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "model_name" in path, "`model_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "model_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateModel_614518(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about a model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   model_name: JString (required)
  ##             : [Required] The name of the model to update.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `model_name` field"
  var valid_614520 = path.getOrDefault("model_name")
  valid_614520 = validateParameter(valid_614520, JString, required = true,
                                 default = nil)
  if valid_614520 != nil:
    section.add "model_name", valid_614520
  var valid_614521 = path.getOrDefault("restapi_id")
  valid_614521 = validateParameter(valid_614521, JString, required = true,
                                 default = nil)
  if valid_614521 != nil:
    section.add "restapi_id", valid_614521
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
  var valid_614522 = header.getOrDefault("X-Amz-Signature")
  valid_614522 = validateParameter(valid_614522, JString, required = false,
                                 default = nil)
  if valid_614522 != nil:
    section.add "X-Amz-Signature", valid_614522
  var valid_614523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "X-Amz-Content-Sha256", valid_614523
  var valid_614524 = header.getOrDefault("X-Amz-Date")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "X-Amz-Date", valid_614524
  var valid_614525 = header.getOrDefault("X-Amz-Credential")
  valid_614525 = validateParameter(valid_614525, JString, required = false,
                                 default = nil)
  if valid_614525 != nil:
    section.add "X-Amz-Credential", valid_614525
  var valid_614526 = header.getOrDefault("X-Amz-Security-Token")
  valid_614526 = validateParameter(valid_614526, JString, required = false,
                                 default = nil)
  if valid_614526 != nil:
    section.add "X-Amz-Security-Token", valid_614526
  var valid_614527 = header.getOrDefault("X-Amz-Algorithm")
  valid_614527 = validateParameter(valid_614527, JString, required = false,
                                 default = nil)
  if valid_614527 != nil:
    section.add "X-Amz-Algorithm", valid_614527
  var valid_614528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614528 = validateParameter(valid_614528, JString, required = false,
                                 default = nil)
  if valid_614528 != nil:
    section.add "X-Amz-SignedHeaders", valid_614528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614530: Call_UpdateModel_614517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_614530.validator(path, query, header, formData, body)
  let scheme = call_614530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614530.url(scheme.get, call_614530.host, call_614530.base,
                         call_614530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614530, url, valid)

proc call*(call_614531: Call_UpdateModel_614517; modelName: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_614532 = newJObject()
  var body_614533 = newJObject()
  add(path_614532, "model_name", newJString(modelName))
  add(path_614532, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614533 = body
  result = call_614531.call(path_614532, nil, nil, nil, body_614533)

var updateModel* = Call_UpdateModel_614517(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_614518,
                                        base: "/", url: url_UpdateModel_614519,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_614502 = ref object of OpenApiRestCall_612642
proc url_DeleteModel_614504(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "model_name" in path, "`model_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "model_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteModel_614503(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   model_name: JString (required)
  ##             : [Required] The name of the model to delete.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `model_name` field"
  var valid_614505 = path.getOrDefault("model_name")
  valid_614505 = validateParameter(valid_614505, JString, required = true,
                                 default = nil)
  if valid_614505 != nil:
    section.add "model_name", valid_614505
  var valid_614506 = path.getOrDefault("restapi_id")
  valid_614506 = validateParameter(valid_614506, JString, required = true,
                                 default = nil)
  if valid_614506 != nil:
    section.add "restapi_id", valid_614506
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
  var valid_614507 = header.getOrDefault("X-Amz-Signature")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Signature", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Content-Sha256", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-Date")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Date", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Credential")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Credential", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-Security-Token")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-Security-Token", valid_614511
  var valid_614512 = header.getOrDefault("X-Amz-Algorithm")
  valid_614512 = validateParameter(valid_614512, JString, required = false,
                                 default = nil)
  if valid_614512 != nil:
    section.add "X-Amz-Algorithm", valid_614512
  var valid_614513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614513 = validateParameter(valid_614513, JString, required = false,
                                 default = nil)
  if valid_614513 != nil:
    section.add "X-Amz-SignedHeaders", valid_614513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614514: Call_DeleteModel_614502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_614514.validator(path, query, header, formData, body)
  let scheme = call_614514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614514.url(scheme.get, call_614514.host, call_614514.base,
                         call_614514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614514, url, valid)

proc call*(call_614515: Call_DeleteModel_614502; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614516 = newJObject()
  add(path_614516, "model_name", newJString(modelName))
  add(path_614516, "restapi_id", newJString(restapiId))
  result = call_614515.call(path_614516, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_614502(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_614503,
                                        base: "/", url: url_DeleteModel_614504,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_614534 = ref object of OpenApiRestCall_612642
proc url_GetRequestValidator_614536(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "requestvalidator_id" in path,
        "`requestvalidator_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/requestvalidators/"),
               (kind: VariableSegment, value: "requestvalidator_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRequestValidator_614535(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidator_id: JString (required)
  ##                      : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614537 = path.getOrDefault("restapi_id")
  valid_614537 = validateParameter(valid_614537, JString, required = true,
                                 default = nil)
  if valid_614537 != nil:
    section.add "restapi_id", valid_614537
  var valid_614538 = path.getOrDefault("requestvalidator_id")
  valid_614538 = validateParameter(valid_614538, JString, required = true,
                                 default = nil)
  if valid_614538 != nil:
    section.add "requestvalidator_id", valid_614538
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
  var valid_614539 = header.getOrDefault("X-Amz-Signature")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "X-Amz-Signature", valid_614539
  var valid_614540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614540 = validateParameter(valid_614540, JString, required = false,
                                 default = nil)
  if valid_614540 != nil:
    section.add "X-Amz-Content-Sha256", valid_614540
  var valid_614541 = header.getOrDefault("X-Amz-Date")
  valid_614541 = validateParameter(valid_614541, JString, required = false,
                                 default = nil)
  if valid_614541 != nil:
    section.add "X-Amz-Date", valid_614541
  var valid_614542 = header.getOrDefault("X-Amz-Credential")
  valid_614542 = validateParameter(valid_614542, JString, required = false,
                                 default = nil)
  if valid_614542 != nil:
    section.add "X-Amz-Credential", valid_614542
  var valid_614543 = header.getOrDefault("X-Amz-Security-Token")
  valid_614543 = validateParameter(valid_614543, JString, required = false,
                                 default = nil)
  if valid_614543 != nil:
    section.add "X-Amz-Security-Token", valid_614543
  var valid_614544 = header.getOrDefault("X-Amz-Algorithm")
  valid_614544 = validateParameter(valid_614544, JString, required = false,
                                 default = nil)
  if valid_614544 != nil:
    section.add "X-Amz-Algorithm", valid_614544
  var valid_614545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614545 = validateParameter(valid_614545, JString, required = false,
                                 default = nil)
  if valid_614545 != nil:
    section.add "X-Amz-SignedHeaders", valid_614545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614546: Call_GetRequestValidator_614534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_614546.validator(path, query, header, formData, body)
  let scheme = call_614546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614546.url(scheme.get, call_614546.host, call_614546.base,
                         call_614546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614546, url, valid)

proc call*(call_614547: Call_GetRequestValidator_614534; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  var path_614548 = newJObject()
  add(path_614548, "restapi_id", newJString(restapiId))
  add(path_614548, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_614547.call(path_614548, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_614534(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_614535, base: "/",
    url: url_GetRequestValidator_614536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_614564 = ref object of OpenApiRestCall_612642
proc url_UpdateRequestValidator_614566(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "requestvalidator_id" in path,
        "`requestvalidator_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/requestvalidators/"),
               (kind: VariableSegment, value: "requestvalidator_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRequestValidator_614565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidator_id: JString (required)
  ##                      : [Required] The identifier of <a>RequestValidator</a> to be updated.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614567 = path.getOrDefault("restapi_id")
  valid_614567 = validateParameter(valid_614567, JString, required = true,
                                 default = nil)
  if valid_614567 != nil:
    section.add "restapi_id", valid_614567
  var valid_614568 = path.getOrDefault("requestvalidator_id")
  valid_614568 = validateParameter(valid_614568, JString, required = true,
                                 default = nil)
  if valid_614568 != nil:
    section.add "requestvalidator_id", valid_614568
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
  var valid_614569 = header.getOrDefault("X-Amz-Signature")
  valid_614569 = validateParameter(valid_614569, JString, required = false,
                                 default = nil)
  if valid_614569 != nil:
    section.add "X-Amz-Signature", valid_614569
  var valid_614570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614570 = validateParameter(valid_614570, JString, required = false,
                                 default = nil)
  if valid_614570 != nil:
    section.add "X-Amz-Content-Sha256", valid_614570
  var valid_614571 = header.getOrDefault("X-Amz-Date")
  valid_614571 = validateParameter(valid_614571, JString, required = false,
                                 default = nil)
  if valid_614571 != nil:
    section.add "X-Amz-Date", valid_614571
  var valid_614572 = header.getOrDefault("X-Amz-Credential")
  valid_614572 = validateParameter(valid_614572, JString, required = false,
                                 default = nil)
  if valid_614572 != nil:
    section.add "X-Amz-Credential", valid_614572
  var valid_614573 = header.getOrDefault("X-Amz-Security-Token")
  valid_614573 = validateParameter(valid_614573, JString, required = false,
                                 default = nil)
  if valid_614573 != nil:
    section.add "X-Amz-Security-Token", valid_614573
  var valid_614574 = header.getOrDefault("X-Amz-Algorithm")
  valid_614574 = validateParameter(valid_614574, JString, required = false,
                                 default = nil)
  if valid_614574 != nil:
    section.add "X-Amz-Algorithm", valid_614574
  var valid_614575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "X-Amz-SignedHeaders", valid_614575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614577: Call_UpdateRequestValidator_614564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_614577.validator(path, query, header, formData, body)
  let scheme = call_614577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614577.url(scheme.get, call_614577.host, call_614577.base,
                         call_614577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614577, url, valid)

proc call*(call_614578: Call_UpdateRequestValidator_614564; restapiId: string;
          requestvalidatorId: string; body: JsonNode): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  var path_614579 = newJObject()
  var body_614580 = newJObject()
  add(path_614579, "restapi_id", newJString(restapiId))
  add(path_614579, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_614580 = body
  result = call_614578.call(path_614579, nil, nil, nil, body_614580)

var updateRequestValidator* = Call_UpdateRequestValidator_614564(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_614565, base: "/",
    url: url_UpdateRequestValidator_614566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_614549 = ref object of OpenApiRestCall_612642
proc url_DeleteRequestValidator_614551(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "requestvalidator_id" in path,
        "`requestvalidator_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/requestvalidators/"),
               (kind: VariableSegment, value: "requestvalidator_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRequestValidator_614550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidator_id: JString (required)
  ##                      : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614552 = path.getOrDefault("restapi_id")
  valid_614552 = validateParameter(valid_614552, JString, required = true,
                                 default = nil)
  if valid_614552 != nil:
    section.add "restapi_id", valid_614552
  var valid_614553 = path.getOrDefault("requestvalidator_id")
  valid_614553 = validateParameter(valid_614553, JString, required = true,
                                 default = nil)
  if valid_614553 != nil:
    section.add "requestvalidator_id", valid_614553
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
  var valid_614554 = header.getOrDefault("X-Amz-Signature")
  valid_614554 = validateParameter(valid_614554, JString, required = false,
                                 default = nil)
  if valid_614554 != nil:
    section.add "X-Amz-Signature", valid_614554
  var valid_614555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614555 = validateParameter(valid_614555, JString, required = false,
                                 default = nil)
  if valid_614555 != nil:
    section.add "X-Amz-Content-Sha256", valid_614555
  var valid_614556 = header.getOrDefault("X-Amz-Date")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "X-Amz-Date", valid_614556
  var valid_614557 = header.getOrDefault("X-Amz-Credential")
  valid_614557 = validateParameter(valid_614557, JString, required = false,
                                 default = nil)
  if valid_614557 != nil:
    section.add "X-Amz-Credential", valid_614557
  var valid_614558 = header.getOrDefault("X-Amz-Security-Token")
  valid_614558 = validateParameter(valid_614558, JString, required = false,
                                 default = nil)
  if valid_614558 != nil:
    section.add "X-Amz-Security-Token", valid_614558
  var valid_614559 = header.getOrDefault("X-Amz-Algorithm")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "X-Amz-Algorithm", valid_614559
  var valid_614560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "X-Amz-SignedHeaders", valid_614560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614561: Call_DeleteRequestValidator_614549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_614561.validator(path, query, header, formData, body)
  let scheme = call_614561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614561.url(scheme.get, call_614561.host, call_614561.base,
                         call_614561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614561, url, valid)

proc call*(call_614562: Call_DeleteRequestValidator_614549; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  var path_614563 = newJObject()
  add(path_614563, "restapi_id", newJString(restapiId))
  add(path_614563, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_614562.call(path_614563, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_614549(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_614550, base: "/",
    url: url_DeleteRequestValidator_614551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_614581 = ref object of OpenApiRestCall_612642
proc url_GetResource_614583(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResource_614582(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists information about a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The identifier for the <a>Resource</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614584 = path.getOrDefault("restapi_id")
  valid_614584 = validateParameter(valid_614584, JString, required = true,
                                 default = nil)
  if valid_614584 != nil:
    section.add "restapi_id", valid_614584
  var valid_614585 = path.getOrDefault("resource_id")
  valid_614585 = validateParameter(valid_614585, JString, required = true,
                                 default = nil)
  if valid_614585 != nil:
    section.add "resource_id", valid_614585
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_614586 = query.getOrDefault("embed")
  valid_614586 = validateParameter(valid_614586, JArray, required = false,
                                 default = nil)
  if valid_614586 != nil:
    section.add "embed", valid_614586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614587 = header.getOrDefault("X-Amz-Signature")
  valid_614587 = validateParameter(valid_614587, JString, required = false,
                                 default = nil)
  if valid_614587 != nil:
    section.add "X-Amz-Signature", valid_614587
  var valid_614588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614588 = validateParameter(valid_614588, JString, required = false,
                                 default = nil)
  if valid_614588 != nil:
    section.add "X-Amz-Content-Sha256", valid_614588
  var valid_614589 = header.getOrDefault("X-Amz-Date")
  valid_614589 = validateParameter(valid_614589, JString, required = false,
                                 default = nil)
  if valid_614589 != nil:
    section.add "X-Amz-Date", valid_614589
  var valid_614590 = header.getOrDefault("X-Amz-Credential")
  valid_614590 = validateParameter(valid_614590, JString, required = false,
                                 default = nil)
  if valid_614590 != nil:
    section.add "X-Amz-Credential", valid_614590
  var valid_614591 = header.getOrDefault("X-Amz-Security-Token")
  valid_614591 = validateParameter(valid_614591, JString, required = false,
                                 default = nil)
  if valid_614591 != nil:
    section.add "X-Amz-Security-Token", valid_614591
  var valid_614592 = header.getOrDefault("X-Amz-Algorithm")
  valid_614592 = validateParameter(valid_614592, JString, required = false,
                                 default = nil)
  if valid_614592 != nil:
    section.add "X-Amz-Algorithm", valid_614592
  var valid_614593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614593 = validateParameter(valid_614593, JString, required = false,
                                 default = nil)
  if valid_614593 != nil:
    section.add "X-Amz-SignedHeaders", valid_614593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614594: Call_GetResource_614581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_614594.validator(path, query, header, formData, body)
  let scheme = call_614594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614594.url(scheme.get, call_614594.host, call_614594.base,
                         call_614594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614594, url, valid)

proc call*(call_614595: Call_GetResource_614581; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_614596 = newJObject()
  var query_614597 = newJObject()
  add(path_614596, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_614597.add "embed", embed
  add(path_614596, "resource_id", newJString(resourceId))
  result = call_614595.call(path_614596, query_614597, nil, nil, nil)

var getResource* = Call_GetResource_614581(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_614582,
                                        base: "/", url: url_GetResource_614583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_614613 = ref object of OpenApiRestCall_612642
proc url_UpdateResource_614615(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResource_614614(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The identifier of the <a>Resource</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614616 = path.getOrDefault("restapi_id")
  valid_614616 = validateParameter(valid_614616, JString, required = true,
                                 default = nil)
  if valid_614616 != nil:
    section.add "restapi_id", valid_614616
  var valid_614617 = path.getOrDefault("resource_id")
  valid_614617 = validateParameter(valid_614617, JString, required = true,
                                 default = nil)
  if valid_614617 != nil:
    section.add "resource_id", valid_614617
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
  var valid_614618 = header.getOrDefault("X-Amz-Signature")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "X-Amz-Signature", valid_614618
  var valid_614619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "X-Amz-Content-Sha256", valid_614619
  var valid_614620 = header.getOrDefault("X-Amz-Date")
  valid_614620 = validateParameter(valid_614620, JString, required = false,
                                 default = nil)
  if valid_614620 != nil:
    section.add "X-Amz-Date", valid_614620
  var valid_614621 = header.getOrDefault("X-Amz-Credential")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "X-Amz-Credential", valid_614621
  var valid_614622 = header.getOrDefault("X-Amz-Security-Token")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-Security-Token", valid_614622
  var valid_614623 = header.getOrDefault("X-Amz-Algorithm")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "X-Amz-Algorithm", valid_614623
  var valid_614624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614624 = validateParameter(valid_614624, JString, required = false,
                                 default = nil)
  if valid_614624 != nil:
    section.add "X-Amz-SignedHeaders", valid_614624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614626: Call_UpdateResource_614613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_614626.validator(path, query, header, formData, body)
  let scheme = call_614626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614626.url(scheme.get, call_614626.host, call_614626.base,
                         call_614626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614626, url, valid)

proc call*(call_614627: Call_UpdateResource_614613; restapiId: string;
          body: JsonNode; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_614628 = newJObject()
  var body_614629 = newJObject()
  add(path_614628, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614629 = body
  add(path_614628, "resource_id", newJString(resourceId))
  result = call_614627.call(path_614628, nil, nil, nil, body_614629)

var updateResource* = Call_UpdateResource_614613(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_614614, base: "/", url: url_UpdateResource_614615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_614598 = ref object of OpenApiRestCall_612642
proc url_DeleteResource_614600(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "resource_id" in path, "`resource_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resource_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResource_614599(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a <a>Resource</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The identifier of the <a>Resource</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614601 = path.getOrDefault("restapi_id")
  valid_614601 = validateParameter(valid_614601, JString, required = true,
                                 default = nil)
  if valid_614601 != nil:
    section.add "restapi_id", valid_614601
  var valid_614602 = path.getOrDefault("resource_id")
  valid_614602 = validateParameter(valid_614602, JString, required = true,
                                 default = nil)
  if valid_614602 != nil:
    section.add "resource_id", valid_614602
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
  var valid_614603 = header.getOrDefault("X-Amz-Signature")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "X-Amz-Signature", valid_614603
  var valid_614604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614604 = validateParameter(valid_614604, JString, required = false,
                                 default = nil)
  if valid_614604 != nil:
    section.add "X-Amz-Content-Sha256", valid_614604
  var valid_614605 = header.getOrDefault("X-Amz-Date")
  valid_614605 = validateParameter(valid_614605, JString, required = false,
                                 default = nil)
  if valid_614605 != nil:
    section.add "X-Amz-Date", valid_614605
  var valid_614606 = header.getOrDefault("X-Amz-Credential")
  valid_614606 = validateParameter(valid_614606, JString, required = false,
                                 default = nil)
  if valid_614606 != nil:
    section.add "X-Amz-Credential", valid_614606
  var valid_614607 = header.getOrDefault("X-Amz-Security-Token")
  valid_614607 = validateParameter(valid_614607, JString, required = false,
                                 default = nil)
  if valid_614607 != nil:
    section.add "X-Amz-Security-Token", valid_614607
  var valid_614608 = header.getOrDefault("X-Amz-Algorithm")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "X-Amz-Algorithm", valid_614608
  var valid_614609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614609 = validateParameter(valid_614609, JString, required = false,
                                 default = nil)
  if valid_614609 != nil:
    section.add "X-Amz-SignedHeaders", valid_614609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614610: Call_DeleteResource_614598; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_614610.validator(path, query, header, formData, body)
  let scheme = call_614610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614610.url(scheme.get, call_614610.host, call_614610.base,
                         call_614610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614610, url, valid)

proc call*(call_614611: Call_DeleteResource_614598; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_614612 = newJObject()
  add(path_614612, "restapi_id", newJString(restapiId))
  add(path_614612, "resource_id", newJString(resourceId))
  result = call_614611.call(path_614612, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_614598(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_614599, base: "/", url: url_DeleteResource_614600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_614644 = ref object of OpenApiRestCall_612642
proc url_PutRestApi_614646(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutRestApi_614645(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614647 = path.getOrDefault("restapi_id")
  valid_614647 = validateParameter(valid_614647, JString, required = true,
                                 default = nil)
  if valid_614647 != nil:
    section.add "restapi_id", valid_614647
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to indicate whether to rollback the API update (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   mode: JString
  ##       : The <code>mode</code> query parameter to specify the update mode. Valid values are "merge" and "overwrite". By default, the update mode is "merge".
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_614648 = query.getOrDefault("failonwarnings")
  valid_614648 = validateParameter(valid_614648, JBool, required = false, default = nil)
  if valid_614648 != nil:
    section.add "failonwarnings", valid_614648
  var valid_614649 = query.getOrDefault("parameters.2.value")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "parameters.2.value", valid_614649
  var valid_614650 = query.getOrDefault("parameters.1.value")
  valid_614650 = validateParameter(valid_614650, JString, required = false,
                                 default = nil)
  if valid_614650 != nil:
    section.add "parameters.1.value", valid_614650
  var valid_614651 = query.getOrDefault("mode")
  valid_614651 = validateParameter(valid_614651, JString, required = false,
                                 default = newJString("merge"))
  if valid_614651 != nil:
    section.add "mode", valid_614651
  var valid_614652 = query.getOrDefault("parameters.1.key")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "parameters.1.key", valid_614652
  var valid_614653 = query.getOrDefault("parameters.2.key")
  valid_614653 = validateParameter(valid_614653, JString, required = false,
                                 default = nil)
  if valid_614653 != nil:
    section.add "parameters.2.key", valid_614653
  var valid_614654 = query.getOrDefault("parameters.0.value")
  valid_614654 = validateParameter(valid_614654, JString, required = false,
                                 default = nil)
  if valid_614654 != nil:
    section.add "parameters.0.value", valid_614654
  var valid_614655 = query.getOrDefault("parameters.0.key")
  valid_614655 = validateParameter(valid_614655, JString, required = false,
                                 default = nil)
  if valid_614655 != nil:
    section.add "parameters.0.key", valid_614655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614656 = header.getOrDefault("X-Amz-Signature")
  valid_614656 = validateParameter(valid_614656, JString, required = false,
                                 default = nil)
  if valid_614656 != nil:
    section.add "X-Amz-Signature", valid_614656
  var valid_614657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614657 = validateParameter(valid_614657, JString, required = false,
                                 default = nil)
  if valid_614657 != nil:
    section.add "X-Amz-Content-Sha256", valid_614657
  var valid_614658 = header.getOrDefault("X-Amz-Date")
  valid_614658 = validateParameter(valid_614658, JString, required = false,
                                 default = nil)
  if valid_614658 != nil:
    section.add "X-Amz-Date", valid_614658
  var valid_614659 = header.getOrDefault("X-Amz-Credential")
  valid_614659 = validateParameter(valid_614659, JString, required = false,
                                 default = nil)
  if valid_614659 != nil:
    section.add "X-Amz-Credential", valid_614659
  var valid_614660 = header.getOrDefault("X-Amz-Security-Token")
  valid_614660 = validateParameter(valid_614660, JString, required = false,
                                 default = nil)
  if valid_614660 != nil:
    section.add "X-Amz-Security-Token", valid_614660
  var valid_614661 = header.getOrDefault("X-Amz-Algorithm")
  valid_614661 = validateParameter(valid_614661, JString, required = false,
                                 default = nil)
  if valid_614661 != nil:
    section.add "X-Amz-Algorithm", valid_614661
  var valid_614662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614662 = validateParameter(valid_614662, JString, required = false,
                                 default = nil)
  if valid_614662 != nil:
    section.add "X-Amz-SignedHeaders", valid_614662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614664: Call_PutRestApi_614644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_614664.validator(path, query, header, formData, body)
  let scheme = call_614664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614664.url(scheme.get, call_614664.host, call_614664.base,
                         call_614664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614664, url, valid)

proc call*(call_614665: Call_PutRestApi_614644; restapiId: string; body: JsonNode;
          failonwarnings: bool = false; parameters2Value: string = "";
          parameters1Value: string = ""; mode: string = "merge";
          parameters1Key: string = ""; parameters2Key: string = "";
          parameters0Value: string = ""; parameters0Key: string = ""): Recallable =
  ## putRestApi
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback the API update (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   parameters2Value: string
  ##   parameters1Value: string
  ##   mode: string
  ##       : The <code>mode</code> query parameter to specify the update mode. Valid values are "merge" and "overwrite". By default, the update mode is "merge".
  ##   parameters1Key: string
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   parameters2Key: string
  ##   body: JObject (required)
  ##   parameters0Value: string
  ##   parameters0Key: string
  var path_614666 = newJObject()
  var query_614667 = newJObject()
  var body_614668 = newJObject()
  add(query_614667, "failonwarnings", newJBool(failonwarnings))
  add(query_614667, "parameters.2.value", newJString(parameters2Value))
  add(query_614667, "parameters.1.value", newJString(parameters1Value))
  add(query_614667, "mode", newJString(mode))
  add(query_614667, "parameters.1.key", newJString(parameters1Key))
  add(path_614666, "restapi_id", newJString(restapiId))
  add(query_614667, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_614668 = body
  add(query_614667, "parameters.0.value", newJString(parameters0Value))
  add(query_614667, "parameters.0.key", newJString(parameters0Key))
  result = call_614665.call(path_614666, query_614667, nil, nil, body_614668)

var putRestApi* = Call_PutRestApi_614644(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_614645,
                                      base: "/", url: url_PutRestApi_614646,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_614630 = ref object of OpenApiRestCall_612642
proc url_GetRestApi_614632(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRestApi_614631(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614633 = path.getOrDefault("restapi_id")
  valid_614633 = validateParameter(valid_614633, JString, required = true,
                                 default = nil)
  if valid_614633 != nil:
    section.add "restapi_id", valid_614633
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
  var valid_614634 = header.getOrDefault("X-Amz-Signature")
  valid_614634 = validateParameter(valid_614634, JString, required = false,
                                 default = nil)
  if valid_614634 != nil:
    section.add "X-Amz-Signature", valid_614634
  var valid_614635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614635 = validateParameter(valid_614635, JString, required = false,
                                 default = nil)
  if valid_614635 != nil:
    section.add "X-Amz-Content-Sha256", valid_614635
  var valid_614636 = header.getOrDefault("X-Amz-Date")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-Date", valid_614636
  var valid_614637 = header.getOrDefault("X-Amz-Credential")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-Credential", valid_614637
  var valid_614638 = header.getOrDefault("X-Amz-Security-Token")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "X-Amz-Security-Token", valid_614638
  var valid_614639 = header.getOrDefault("X-Amz-Algorithm")
  valid_614639 = validateParameter(valid_614639, JString, required = false,
                                 default = nil)
  if valid_614639 != nil:
    section.add "X-Amz-Algorithm", valid_614639
  var valid_614640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = nil)
  if valid_614640 != nil:
    section.add "X-Amz-SignedHeaders", valid_614640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614641: Call_GetRestApi_614630; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_614641.validator(path, query, header, formData, body)
  let scheme = call_614641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614641.url(scheme.get, call_614641.host, call_614641.base,
                         call_614641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614641, url, valid)

proc call*(call_614642: Call_GetRestApi_614630; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614643 = newJObject()
  add(path_614643, "restapi_id", newJString(restapiId))
  result = call_614642.call(path_614643, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_614630(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_614631,
                                      base: "/", url: url_GetRestApi_614632,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_614683 = ref object of OpenApiRestCall_612642
proc url_UpdateRestApi_614685(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRestApi_614684(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about the specified API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614686 = path.getOrDefault("restapi_id")
  valid_614686 = validateParameter(valid_614686, JString, required = true,
                                 default = nil)
  if valid_614686 != nil:
    section.add "restapi_id", valid_614686
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
  var valid_614687 = header.getOrDefault("X-Amz-Signature")
  valid_614687 = validateParameter(valid_614687, JString, required = false,
                                 default = nil)
  if valid_614687 != nil:
    section.add "X-Amz-Signature", valid_614687
  var valid_614688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614688 = validateParameter(valid_614688, JString, required = false,
                                 default = nil)
  if valid_614688 != nil:
    section.add "X-Amz-Content-Sha256", valid_614688
  var valid_614689 = header.getOrDefault("X-Amz-Date")
  valid_614689 = validateParameter(valid_614689, JString, required = false,
                                 default = nil)
  if valid_614689 != nil:
    section.add "X-Amz-Date", valid_614689
  var valid_614690 = header.getOrDefault("X-Amz-Credential")
  valid_614690 = validateParameter(valid_614690, JString, required = false,
                                 default = nil)
  if valid_614690 != nil:
    section.add "X-Amz-Credential", valid_614690
  var valid_614691 = header.getOrDefault("X-Amz-Security-Token")
  valid_614691 = validateParameter(valid_614691, JString, required = false,
                                 default = nil)
  if valid_614691 != nil:
    section.add "X-Amz-Security-Token", valid_614691
  var valid_614692 = header.getOrDefault("X-Amz-Algorithm")
  valid_614692 = validateParameter(valid_614692, JString, required = false,
                                 default = nil)
  if valid_614692 != nil:
    section.add "X-Amz-Algorithm", valid_614692
  var valid_614693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614693 = validateParameter(valid_614693, JString, required = false,
                                 default = nil)
  if valid_614693 != nil:
    section.add "X-Amz-SignedHeaders", valid_614693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614695: Call_UpdateRestApi_614683; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_614695.validator(path, query, header, formData, body)
  let scheme = call_614695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614695.url(scheme.get, call_614695.host, call_614695.base,
                         call_614695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614695, url, valid)

proc call*(call_614696: Call_UpdateRestApi_614683; restapiId: string; body: JsonNode): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_614697 = newJObject()
  var body_614698 = newJObject()
  add(path_614697, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614698 = body
  result = call_614696.call(path_614697, nil, nil, nil, body_614698)

var updateRestApi* = Call_UpdateRestApi_614683(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_614684,
    base: "/", url: url_UpdateRestApi_614685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_614669 = ref object of OpenApiRestCall_612642
proc url_DeleteRestApi_614671(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRestApi_614670(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614672 = path.getOrDefault("restapi_id")
  valid_614672 = validateParameter(valid_614672, JString, required = true,
                                 default = nil)
  if valid_614672 != nil:
    section.add "restapi_id", valid_614672
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
  var valid_614673 = header.getOrDefault("X-Amz-Signature")
  valid_614673 = validateParameter(valid_614673, JString, required = false,
                                 default = nil)
  if valid_614673 != nil:
    section.add "X-Amz-Signature", valid_614673
  var valid_614674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614674 = validateParameter(valid_614674, JString, required = false,
                                 default = nil)
  if valid_614674 != nil:
    section.add "X-Amz-Content-Sha256", valid_614674
  var valid_614675 = header.getOrDefault("X-Amz-Date")
  valid_614675 = validateParameter(valid_614675, JString, required = false,
                                 default = nil)
  if valid_614675 != nil:
    section.add "X-Amz-Date", valid_614675
  var valid_614676 = header.getOrDefault("X-Amz-Credential")
  valid_614676 = validateParameter(valid_614676, JString, required = false,
                                 default = nil)
  if valid_614676 != nil:
    section.add "X-Amz-Credential", valid_614676
  var valid_614677 = header.getOrDefault("X-Amz-Security-Token")
  valid_614677 = validateParameter(valid_614677, JString, required = false,
                                 default = nil)
  if valid_614677 != nil:
    section.add "X-Amz-Security-Token", valid_614677
  var valid_614678 = header.getOrDefault("X-Amz-Algorithm")
  valid_614678 = validateParameter(valid_614678, JString, required = false,
                                 default = nil)
  if valid_614678 != nil:
    section.add "X-Amz-Algorithm", valid_614678
  var valid_614679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614679 = validateParameter(valid_614679, JString, required = false,
                                 default = nil)
  if valid_614679 != nil:
    section.add "X-Amz-SignedHeaders", valid_614679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614680: Call_DeleteRestApi_614669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_614680.validator(path, query, header, formData, body)
  let scheme = call_614680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614680.url(scheme.get, call_614680.host, call_614680.base,
                         call_614680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614680, url, valid)

proc call*(call_614681: Call_DeleteRestApi_614669; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614682 = newJObject()
  add(path_614682, "restapi_id", newJString(restapiId))
  result = call_614681.call(path_614682, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_614669(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_614670,
    base: "/", url: url_DeleteRestApi_614671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_614699 = ref object of OpenApiRestCall_612642
proc url_GetStage_614701(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "stage_name" in path, "`stage_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stage_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStage_614700(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> resource to get information about.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614702 = path.getOrDefault("restapi_id")
  valid_614702 = validateParameter(valid_614702, JString, required = true,
                                 default = nil)
  if valid_614702 != nil:
    section.add "restapi_id", valid_614702
  var valid_614703 = path.getOrDefault("stage_name")
  valid_614703 = validateParameter(valid_614703, JString, required = true,
                                 default = nil)
  if valid_614703 != nil:
    section.add "stage_name", valid_614703
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
  var valid_614704 = header.getOrDefault("X-Amz-Signature")
  valid_614704 = validateParameter(valid_614704, JString, required = false,
                                 default = nil)
  if valid_614704 != nil:
    section.add "X-Amz-Signature", valid_614704
  var valid_614705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614705 = validateParameter(valid_614705, JString, required = false,
                                 default = nil)
  if valid_614705 != nil:
    section.add "X-Amz-Content-Sha256", valid_614705
  var valid_614706 = header.getOrDefault("X-Amz-Date")
  valid_614706 = validateParameter(valid_614706, JString, required = false,
                                 default = nil)
  if valid_614706 != nil:
    section.add "X-Amz-Date", valid_614706
  var valid_614707 = header.getOrDefault("X-Amz-Credential")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "X-Amz-Credential", valid_614707
  var valid_614708 = header.getOrDefault("X-Amz-Security-Token")
  valid_614708 = validateParameter(valid_614708, JString, required = false,
                                 default = nil)
  if valid_614708 != nil:
    section.add "X-Amz-Security-Token", valid_614708
  var valid_614709 = header.getOrDefault("X-Amz-Algorithm")
  valid_614709 = validateParameter(valid_614709, JString, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "X-Amz-Algorithm", valid_614709
  var valid_614710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "X-Amz-SignedHeaders", valid_614710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614711: Call_GetStage_614699; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_614711.validator(path, query, header, formData, body)
  let scheme = call_614711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614711.url(scheme.get, call_614711.host, call_614711.base,
                         call_614711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614711, url, valid)

proc call*(call_614712: Call_GetStage_614699; restapiId: string; stageName: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  var path_614713 = newJObject()
  add(path_614713, "restapi_id", newJString(restapiId))
  add(path_614713, "stage_name", newJString(stageName))
  result = call_614712.call(path_614713, nil, nil, nil, nil)

var getStage* = Call_GetStage_614699(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_614700, base: "/",
                                  url: url_GetStage_614701,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_614729 = ref object of OpenApiRestCall_612642
proc url_UpdateStage_614731(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "stage_name" in path, "`stage_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stage_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStage_614730(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> resource to change information about.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614732 = path.getOrDefault("restapi_id")
  valid_614732 = validateParameter(valid_614732, JString, required = true,
                                 default = nil)
  if valid_614732 != nil:
    section.add "restapi_id", valid_614732
  var valid_614733 = path.getOrDefault("stage_name")
  valid_614733 = validateParameter(valid_614733, JString, required = true,
                                 default = nil)
  if valid_614733 != nil:
    section.add "stage_name", valid_614733
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
  var valid_614734 = header.getOrDefault("X-Amz-Signature")
  valid_614734 = validateParameter(valid_614734, JString, required = false,
                                 default = nil)
  if valid_614734 != nil:
    section.add "X-Amz-Signature", valid_614734
  var valid_614735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614735 = validateParameter(valid_614735, JString, required = false,
                                 default = nil)
  if valid_614735 != nil:
    section.add "X-Amz-Content-Sha256", valid_614735
  var valid_614736 = header.getOrDefault("X-Amz-Date")
  valid_614736 = validateParameter(valid_614736, JString, required = false,
                                 default = nil)
  if valid_614736 != nil:
    section.add "X-Amz-Date", valid_614736
  var valid_614737 = header.getOrDefault("X-Amz-Credential")
  valid_614737 = validateParameter(valid_614737, JString, required = false,
                                 default = nil)
  if valid_614737 != nil:
    section.add "X-Amz-Credential", valid_614737
  var valid_614738 = header.getOrDefault("X-Amz-Security-Token")
  valid_614738 = validateParameter(valid_614738, JString, required = false,
                                 default = nil)
  if valid_614738 != nil:
    section.add "X-Amz-Security-Token", valid_614738
  var valid_614739 = header.getOrDefault("X-Amz-Algorithm")
  valid_614739 = validateParameter(valid_614739, JString, required = false,
                                 default = nil)
  if valid_614739 != nil:
    section.add "X-Amz-Algorithm", valid_614739
  var valid_614740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614740 = validateParameter(valid_614740, JString, required = false,
                                 default = nil)
  if valid_614740 != nil:
    section.add "X-Amz-SignedHeaders", valid_614740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614742: Call_UpdateStage_614729; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_614742.validator(path, query, header, formData, body)
  let scheme = call_614742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614742.url(scheme.get, call_614742.host, call_614742.base,
                         call_614742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614742, url, valid)

proc call*(call_614743: Call_UpdateStage_614729; restapiId: string; body: JsonNode;
          stageName: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  var path_614744 = newJObject()
  var body_614745 = newJObject()
  add(path_614744, "restapi_id", newJString(restapiId))
  if body != nil:
    body_614745 = body
  add(path_614744, "stage_name", newJString(stageName))
  result = call_614743.call(path_614744, nil, nil, nil, body_614745)

var updateStage* = Call_UpdateStage_614729(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_614730,
                                        base: "/", url: url_UpdateStage_614731,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_614714 = ref object of OpenApiRestCall_612642
proc url_DeleteStage_614716(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "stage_name" in path, "`stage_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stage_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStage_614715(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <a>Stage</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> resource to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614717 = path.getOrDefault("restapi_id")
  valid_614717 = validateParameter(valid_614717, JString, required = true,
                                 default = nil)
  if valid_614717 != nil:
    section.add "restapi_id", valid_614717
  var valid_614718 = path.getOrDefault("stage_name")
  valid_614718 = validateParameter(valid_614718, JString, required = true,
                                 default = nil)
  if valid_614718 != nil:
    section.add "stage_name", valid_614718
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
  var valid_614719 = header.getOrDefault("X-Amz-Signature")
  valid_614719 = validateParameter(valid_614719, JString, required = false,
                                 default = nil)
  if valid_614719 != nil:
    section.add "X-Amz-Signature", valid_614719
  var valid_614720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614720 = validateParameter(valid_614720, JString, required = false,
                                 default = nil)
  if valid_614720 != nil:
    section.add "X-Amz-Content-Sha256", valid_614720
  var valid_614721 = header.getOrDefault("X-Amz-Date")
  valid_614721 = validateParameter(valid_614721, JString, required = false,
                                 default = nil)
  if valid_614721 != nil:
    section.add "X-Amz-Date", valid_614721
  var valid_614722 = header.getOrDefault("X-Amz-Credential")
  valid_614722 = validateParameter(valid_614722, JString, required = false,
                                 default = nil)
  if valid_614722 != nil:
    section.add "X-Amz-Credential", valid_614722
  var valid_614723 = header.getOrDefault("X-Amz-Security-Token")
  valid_614723 = validateParameter(valid_614723, JString, required = false,
                                 default = nil)
  if valid_614723 != nil:
    section.add "X-Amz-Security-Token", valid_614723
  var valid_614724 = header.getOrDefault("X-Amz-Algorithm")
  valid_614724 = validateParameter(valid_614724, JString, required = false,
                                 default = nil)
  if valid_614724 != nil:
    section.add "X-Amz-Algorithm", valid_614724
  var valid_614725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614725 = validateParameter(valid_614725, JString, required = false,
                                 default = nil)
  if valid_614725 != nil:
    section.add "X-Amz-SignedHeaders", valid_614725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614726: Call_DeleteStage_614714; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_614726.validator(path, query, header, formData, body)
  let scheme = call_614726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614726.url(scheme.get, call_614726.host, call_614726.base,
                         call_614726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614726, url, valid)

proc call*(call_614727: Call_DeleteStage_614714; restapiId: string; stageName: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  var path_614728 = newJObject()
  add(path_614728, "restapi_id", newJString(restapiId))
  add(path_614728, "stage_name", newJString(stageName))
  result = call_614727.call(path_614728, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_614714(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_614715,
                                        base: "/", url: url_DeleteStage_614716,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_614746 = ref object of OpenApiRestCall_612642
proc url_GetUsagePlan_614748(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsagePlan_614747(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a usage plan of a given plan identifier.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_614749 = path.getOrDefault("usageplanId")
  valid_614749 = validateParameter(valid_614749, JString, required = true,
                                 default = nil)
  if valid_614749 != nil:
    section.add "usageplanId", valid_614749
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
  var valid_614750 = header.getOrDefault("X-Amz-Signature")
  valid_614750 = validateParameter(valid_614750, JString, required = false,
                                 default = nil)
  if valid_614750 != nil:
    section.add "X-Amz-Signature", valid_614750
  var valid_614751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614751 = validateParameter(valid_614751, JString, required = false,
                                 default = nil)
  if valid_614751 != nil:
    section.add "X-Amz-Content-Sha256", valid_614751
  var valid_614752 = header.getOrDefault("X-Amz-Date")
  valid_614752 = validateParameter(valid_614752, JString, required = false,
                                 default = nil)
  if valid_614752 != nil:
    section.add "X-Amz-Date", valid_614752
  var valid_614753 = header.getOrDefault("X-Amz-Credential")
  valid_614753 = validateParameter(valid_614753, JString, required = false,
                                 default = nil)
  if valid_614753 != nil:
    section.add "X-Amz-Credential", valid_614753
  var valid_614754 = header.getOrDefault("X-Amz-Security-Token")
  valid_614754 = validateParameter(valid_614754, JString, required = false,
                                 default = nil)
  if valid_614754 != nil:
    section.add "X-Amz-Security-Token", valid_614754
  var valid_614755 = header.getOrDefault("X-Amz-Algorithm")
  valid_614755 = validateParameter(valid_614755, JString, required = false,
                                 default = nil)
  if valid_614755 != nil:
    section.add "X-Amz-Algorithm", valid_614755
  var valid_614756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614756 = validateParameter(valid_614756, JString, required = false,
                                 default = nil)
  if valid_614756 != nil:
    section.add "X-Amz-SignedHeaders", valid_614756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614757: Call_GetUsagePlan_614746; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_614757.validator(path, query, header, formData, body)
  let scheme = call_614757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614757.url(scheme.get, call_614757.host, call_614757.base,
                         call_614757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614757, url, valid)

proc call*(call_614758: Call_GetUsagePlan_614746; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_614759 = newJObject()
  add(path_614759, "usageplanId", newJString(usageplanId))
  result = call_614758.call(path_614759, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_614746(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_614747,
    base: "/", url: url_GetUsagePlan_614748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_614774 = ref object of OpenApiRestCall_612642
proc url_UpdateUsagePlan_614776(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUsagePlan_614775(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a usage plan of a given plan Id.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_614777 = path.getOrDefault("usageplanId")
  valid_614777 = validateParameter(valid_614777, JString, required = true,
                                 default = nil)
  if valid_614777 != nil:
    section.add "usageplanId", valid_614777
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
  var valid_614778 = header.getOrDefault("X-Amz-Signature")
  valid_614778 = validateParameter(valid_614778, JString, required = false,
                                 default = nil)
  if valid_614778 != nil:
    section.add "X-Amz-Signature", valid_614778
  var valid_614779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614779 = validateParameter(valid_614779, JString, required = false,
                                 default = nil)
  if valid_614779 != nil:
    section.add "X-Amz-Content-Sha256", valid_614779
  var valid_614780 = header.getOrDefault("X-Amz-Date")
  valid_614780 = validateParameter(valid_614780, JString, required = false,
                                 default = nil)
  if valid_614780 != nil:
    section.add "X-Amz-Date", valid_614780
  var valid_614781 = header.getOrDefault("X-Amz-Credential")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "X-Amz-Credential", valid_614781
  var valid_614782 = header.getOrDefault("X-Amz-Security-Token")
  valid_614782 = validateParameter(valid_614782, JString, required = false,
                                 default = nil)
  if valid_614782 != nil:
    section.add "X-Amz-Security-Token", valid_614782
  var valid_614783 = header.getOrDefault("X-Amz-Algorithm")
  valid_614783 = validateParameter(valid_614783, JString, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "X-Amz-Algorithm", valid_614783
  var valid_614784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "X-Amz-SignedHeaders", valid_614784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614786: Call_UpdateUsagePlan_614774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_614786.validator(path, query, header, formData, body)
  let scheme = call_614786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614786.url(scheme.get, call_614786.host, call_614786.base,
                         call_614786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614786, url, valid)

proc call*(call_614787: Call_UpdateUsagePlan_614774; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_614788 = newJObject()
  var body_614789 = newJObject()
  add(path_614788, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_614789 = body
  result = call_614787.call(path_614788, nil, nil, nil, body_614789)

var updateUsagePlan* = Call_UpdateUsagePlan_614774(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_614775,
    base: "/", url: url_UpdateUsagePlan_614776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_614760 = ref object of OpenApiRestCall_612642
proc url_DeleteUsagePlan_614762(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUsagePlan_614761(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a usage plan of a given plan Id.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_614763 = path.getOrDefault("usageplanId")
  valid_614763 = validateParameter(valid_614763, JString, required = true,
                                 default = nil)
  if valid_614763 != nil:
    section.add "usageplanId", valid_614763
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
  var valid_614764 = header.getOrDefault("X-Amz-Signature")
  valid_614764 = validateParameter(valid_614764, JString, required = false,
                                 default = nil)
  if valid_614764 != nil:
    section.add "X-Amz-Signature", valid_614764
  var valid_614765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614765 = validateParameter(valid_614765, JString, required = false,
                                 default = nil)
  if valid_614765 != nil:
    section.add "X-Amz-Content-Sha256", valid_614765
  var valid_614766 = header.getOrDefault("X-Amz-Date")
  valid_614766 = validateParameter(valid_614766, JString, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "X-Amz-Date", valid_614766
  var valid_614767 = header.getOrDefault("X-Amz-Credential")
  valid_614767 = validateParameter(valid_614767, JString, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "X-Amz-Credential", valid_614767
  var valid_614768 = header.getOrDefault("X-Amz-Security-Token")
  valid_614768 = validateParameter(valid_614768, JString, required = false,
                                 default = nil)
  if valid_614768 != nil:
    section.add "X-Amz-Security-Token", valid_614768
  var valid_614769 = header.getOrDefault("X-Amz-Algorithm")
  valid_614769 = validateParameter(valid_614769, JString, required = false,
                                 default = nil)
  if valid_614769 != nil:
    section.add "X-Amz-Algorithm", valid_614769
  var valid_614770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614770 = validateParameter(valid_614770, JString, required = false,
                                 default = nil)
  if valid_614770 != nil:
    section.add "X-Amz-SignedHeaders", valid_614770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614771: Call_DeleteUsagePlan_614760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_614771.validator(path, query, header, formData, body)
  let scheme = call_614771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614771.url(scheme.get, call_614771.host, call_614771.base,
                         call_614771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614771, url, valid)

proc call*(call_614772: Call_DeleteUsagePlan_614760; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_614773 = newJObject()
  add(path_614773, "usageplanId", newJString(usageplanId))
  result = call_614772.call(path_614773, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_614760(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_614761,
    base: "/", url: url_DeleteUsagePlan_614762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_614790 = ref object of OpenApiRestCall_612642
proc url_GetUsagePlanKey_614792(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  assert "keyId" in path, "`keyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/keys/"),
               (kind: VariableSegment, value: "keyId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsagePlanKey_614791(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a usage plan key of a given key identifier.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: JString (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_614793 = path.getOrDefault("usageplanId")
  valid_614793 = validateParameter(valid_614793, JString, required = true,
                                 default = nil)
  if valid_614793 != nil:
    section.add "usageplanId", valid_614793
  var valid_614794 = path.getOrDefault("keyId")
  valid_614794 = validateParameter(valid_614794, JString, required = true,
                                 default = nil)
  if valid_614794 != nil:
    section.add "keyId", valid_614794
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
  var valid_614795 = header.getOrDefault("X-Amz-Signature")
  valid_614795 = validateParameter(valid_614795, JString, required = false,
                                 default = nil)
  if valid_614795 != nil:
    section.add "X-Amz-Signature", valid_614795
  var valid_614796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614796 = validateParameter(valid_614796, JString, required = false,
                                 default = nil)
  if valid_614796 != nil:
    section.add "X-Amz-Content-Sha256", valid_614796
  var valid_614797 = header.getOrDefault("X-Amz-Date")
  valid_614797 = validateParameter(valid_614797, JString, required = false,
                                 default = nil)
  if valid_614797 != nil:
    section.add "X-Amz-Date", valid_614797
  var valid_614798 = header.getOrDefault("X-Amz-Credential")
  valid_614798 = validateParameter(valid_614798, JString, required = false,
                                 default = nil)
  if valid_614798 != nil:
    section.add "X-Amz-Credential", valid_614798
  var valid_614799 = header.getOrDefault("X-Amz-Security-Token")
  valid_614799 = validateParameter(valid_614799, JString, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "X-Amz-Security-Token", valid_614799
  var valid_614800 = header.getOrDefault("X-Amz-Algorithm")
  valid_614800 = validateParameter(valid_614800, JString, required = false,
                                 default = nil)
  if valid_614800 != nil:
    section.add "X-Amz-Algorithm", valid_614800
  var valid_614801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614801 = validateParameter(valid_614801, JString, required = false,
                                 default = nil)
  if valid_614801 != nil:
    section.add "X-Amz-SignedHeaders", valid_614801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614802: Call_GetUsagePlanKey_614790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_614802.validator(path, query, header, formData, body)
  let scheme = call_614802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614802.url(scheme.get, call_614802.host, call_614802.base,
                         call_614802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614802, url, valid)

proc call*(call_614803: Call_GetUsagePlanKey_614790; usageplanId: string;
          keyId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_614804 = newJObject()
  add(path_614804, "usageplanId", newJString(usageplanId))
  add(path_614804, "keyId", newJString(keyId))
  result = call_614803.call(path_614804, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_614790(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_614791, base: "/", url: url_GetUsagePlanKey_614792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_614805 = ref object of OpenApiRestCall_612642
proc url_DeleteUsagePlanKey_614807(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  assert "keyId" in path, "`keyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/keys/"),
               (kind: VariableSegment, value: "keyId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUsagePlanKey_614806(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: JString (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_614808 = path.getOrDefault("usageplanId")
  valid_614808 = validateParameter(valid_614808, JString, required = true,
                                 default = nil)
  if valid_614808 != nil:
    section.add "usageplanId", valid_614808
  var valid_614809 = path.getOrDefault("keyId")
  valid_614809 = validateParameter(valid_614809, JString, required = true,
                                 default = nil)
  if valid_614809 != nil:
    section.add "keyId", valid_614809
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
  var valid_614810 = header.getOrDefault("X-Amz-Signature")
  valid_614810 = validateParameter(valid_614810, JString, required = false,
                                 default = nil)
  if valid_614810 != nil:
    section.add "X-Amz-Signature", valid_614810
  var valid_614811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614811 = validateParameter(valid_614811, JString, required = false,
                                 default = nil)
  if valid_614811 != nil:
    section.add "X-Amz-Content-Sha256", valid_614811
  var valid_614812 = header.getOrDefault("X-Amz-Date")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-Date", valid_614812
  var valid_614813 = header.getOrDefault("X-Amz-Credential")
  valid_614813 = validateParameter(valid_614813, JString, required = false,
                                 default = nil)
  if valid_614813 != nil:
    section.add "X-Amz-Credential", valid_614813
  var valid_614814 = header.getOrDefault("X-Amz-Security-Token")
  valid_614814 = validateParameter(valid_614814, JString, required = false,
                                 default = nil)
  if valid_614814 != nil:
    section.add "X-Amz-Security-Token", valid_614814
  var valid_614815 = header.getOrDefault("X-Amz-Algorithm")
  valid_614815 = validateParameter(valid_614815, JString, required = false,
                                 default = nil)
  if valid_614815 != nil:
    section.add "X-Amz-Algorithm", valid_614815
  var valid_614816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614816 = validateParameter(valid_614816, JString, required = false,
                                 default = nil)
  if valid_614816 != nil:
    section.add "X-Amz-SignedHeaders", valid_614816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614817: Call_DeleteUsagePlanKey_614805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_614817.validator(path, query, header, formData, body)
  let scheme = call_614817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614817.url(scheme.get, call_614817.host, call_614817.base,
                         call_614817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614817, url, valid)

proc call*(call_614818: Call_DeleteUsagePlanKey_614805; usageplanId: string;
          keyId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  var path_614819 = newJObject()
  add(path_614819, "usageplanId", newJString(usageplanId))
  add(path_614819, "keyId", newJString(keyId))
  result = call_614818.call(path_614819, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_614805(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_614806, base: "/",
    url: url_DeleteUsagePlanKey_614807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_614820 = ref object of OpenApiRestCall_612642
proc url_GetVpcLink_614822(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVpcLink_614821(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   vpclink_id: JString (required)
  ##             : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `vpclink_id` field"
  var valid_614823 = path.getOrDefault("vpclink_id")
  valid_614823 = validateParameter(valid_614823, JString, required = true,
                                 default = nil)
  if valid_614823 != nil:
    section.add "vpclink_id", valid_614823
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
  var valid_614824 = header.getOrDefault("X-Amz-Signature")
  valid_614824 = validateParameter(valid_614824, JString, required = false,
                                 default = nil)
  if valid_614824 != nil:
    section.add "X-Amz-Signature", valid_614824
  var valid_614825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614825 = validateParameter(valid_614825, JString, required = false,
                                 default = nil)
  if valid_614825 != nil:
    section.add "X-Amz-Content-Sha256", valid_614825
  var valid_614826 = header.getOrDefault("X-Amz-Date")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "X-Amz-Date", valid_614826
  var valid_614827 = header.getOrDefault("X-Amz-Credential")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "X-Amz-Credential", valid_614827
  var valid_614828 = header.getOrDefault("X-Amz-Security-Token")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-Security-Token", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-Algorithm")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-Algorithm", valid_614829
  var valid_614830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614830 = validateParameter(valid_614830, JString, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "X-Amz-SignedHeaders", valid_614830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614831: Call_GetVpcLink_614820; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_614831.validator(path, query, header, formData, body)
  let scheme = call_614831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614831.url(scheme.get, call_614831.host, call_614831.base,
                         call_614831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614831, url, valid)

proc call*(call_614832: Call_GetVpcLink_614820; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_614833 = newJObject()
  add(path_614833, "vpclink_id", newJString(vpclinkId))
  result = call_614832.call(path_614833, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_614820(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_614821,
                                      base: "/", url: url_GetVpcLink_614822,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_614848 = ref object of OpenApiRestCall_612642
proc url_UpdateVpcLink_614850(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVpcLink_614849(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   vpclink_id: JString (required)
  ##             : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `vpclink_id` field"
  var valid_614851 = path.getOrDefault("vpclink_id")
  valid_614851 = validateParameter(valid_614851, JString, required = true,
                                 default = nil)
  if valid_614851 != nil:
    section.add "vpclink_id", valid_614851
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
  var valid_614852 = header.getOrDefault("X-Amz-Signature")
  valid_614852 = validateParameter(valid_614852, JString, required = false,
                                 default = nil)
  if valid_614852 != nil:
    section.add "X-Amz-Signature", valid_614852
  var valid_614853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614853 = validateParameter(valid_614853, JString, required = false,
                                 default = nil)
  if valid_614853 != nil:
    section.add "X-Amz-Content-Sha256", valid_614853
  var valid_614854 = header.getOrDefault("X-Amz-Date")
  valid_614854 = validateParameter(valid_614854, JString, required = false,
                                 default = nil)
  if valid_614854 != nil:
    section.add "X-Amz-Date", valid_614854
  var valid_614855 = header.getOrDefault("X-Amz-Credential")
  valid_614855 = validateParameter(valid_614855, JString, required = false,
                                 default = nil)
  if valid_614855 != nil:
    section.add "X-Amz-Credential", valid_614855
  var valid_614856 = header.getOrDefault("X-Amz-Security-Token")
  valid_614856 = validateParameter(valid_614856, JString, required = false,
                                 default = nil)
  if valid_614856 != nil:
    section.add "X-Amz-Security-Token", valid_614856
  var valid_614857 = header.getOrDefault("X-Amz-Algorithm")
  valid_614857 = validateParameter(valid_614857, JString, required = false,
                                 default = nil)
  if valid_614857 != nil:
    section.add "X-Amz-Algorithm", valid_614857
  var valid_614858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614858 = validateParameter(valid_614858, JString, required = false,
                                 default = nil)
  if valid_614858 != nil:
    section.add "X-Amz-SignedHeaders", valid_614858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614860: Call_UpdateVpcLink_614848; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_614860.validator(path, query, header, formData, body)
  let scheme = call_614860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614860.url(scheme.get, call_614860.host, call_614860.base,
                         call_614860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614860, url, valid)

proc call*(call_614861: Call_UpdateVpcLink_614848; vpclinkId: string; body: JsonNode): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  ##   body: JObject (required)
  var path_614862 = newJObject()
  var body_614863 = newJObject()
  add(path_614862, "vpclink_id", newJString(vpclinkId))
  if body != nil:
    body_614863 = body
  result = call_614861.call(path_614862, nil, nil, nil, body_614863)

var updateVpcLink* = Call_UpdateVpcLink_614848(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_614849,
    base: "/", url: url_UpdateVpcLink_614850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_614834 = ref object of OpenApiRestCall_612642
proc url_DeleteVpcLink_614836(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVpcLink_614835(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   vpclink_id: JString (required)
  ##             : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `vpclink_id` field"
  var valid_614837 = path.getOrDefault("vpclink_id")
  valid_614837 = validateParameter(valid_614837, JString, required = true,
                                 default = nil)
  if valid_614837 != nil:
    section.add "vpclink_id", valid_614837
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
  var valid_614838 = header.getOrDefault("X-Amz-Signature")
  valid_614838 = validateParameter(valid_614838, JString, required = false,
                                 default = nil)
  if valid_614838 != nil:
    section.add "X-Amz-Signature", valid_614838
  var valid_614839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614839 = validateParameter(valid_614839, JString, required = false,
                                 default = nil)
  if valid_614839 != nil:
    section.add "X-Amz-Content-Sha256", valid_614839
  var valid_614840 = header.getOrDefault("X-Amz-Date")
  valid_614840 = validateParameter(valid_614840, JString, required = false,
                                 default = nil)
  if valid_614840 != nil:
    section.add "X-Amz-Date", valid_614840
  var valid_614841 = header.getOrDefault("X-Amz-Credential")
  valid_614841 = validateParameter(valid_614841, JString, required = false,
                                 default = nil)
  if valid_614841 != nil:
    section.add "X-Amz-Credential", valid_614841
  var valid_614842 = header.getOrDefault("X-Amz-Security-Token")
  valid_614842 = validateParameter(valid_614842, JString, required = false,
                                 default = nil)
  if valid_614842 != nil:
    section.add "X-Amz-Security-Token", valid_614842
  var valid_614843 = header.getOrDefault("X-Amz-Algorithm")
  valid_614843 = validateParameter(valid_614843, JString, required = false,
                                 default = nil)
  if valid_614843 != nil:
    section.add "X-Amz-Algorithm", valid_614843
  var valid_614844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "X-Amz-SignedHeaders", valid_614844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614845: Call_DeleteVpcLink_614834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_614845.validator(path, query, header, formData, body)
  let scheme = call_614845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614845.url(scheme.get, call_614845.host, call_614845.base,
                         call_614845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614845, url, valid)

proc call*(call_614846: Call_DeleteVpcLink_614834; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_614847 = newJObject()
  add(path_614847, "vpclink_id", newJString(vpclinkId))
  result = call_614846.call(path_614847, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_614834(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_614835,
    base: "/", url: url_DeleteVpcLink_614836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_614864 = ref object of OpenApiRestCall_612642
proc url_FlushStageAuthorizersCache_614866(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "stage_name" in path, "`stage_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stage_name"),
               (kind: ConstantSegment, value: "/cache/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FlushStageAuthorizersCache_614865(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : The string identifier of the associated <a>RestApi</a>.
  ##   stage_name: JString (required)
  ##             : The name of the stage to flush.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614867 = path.getOrDefault("restapi_id")
  valid_614867 = validateParameter(valid_614867, JString, required = true,
                                 default = nil)
  if valid_614867 != nil:
    section.add "restapi_id", valid_614867
  var valid_614868 = path.getOrDefault("stage_name")
  valid_614868 = validateParameter(valid_614868, JString, required = true,
                                 default = nil)
  if valid_614868 != nil:
    section.add "stage_name", valid_614868
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
  var valid_614869 = header.getOrDefault("X-Amz-Signature")
  valid_614869 = validateParameter(valid_614869, JString, required = false,
                                 default = nil)
  if valid_614869 != nil:
    section.add "X-Amz-Signature", valid_614869
  var valid_614870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614870 = validateParameter(valid_614870, JString, required = false,
                                 default = nil)
  if valid_614870 != nil:
    section.add "X-Amz-Content-Sha256", valid_614870
  var valid_614871 = header.getOrDefault("X-Amz-Date")
  valid_614871 = validateParameter(valid_614871, JString, required = false,
                                 default = nil)
  if valid_614871 != nil:
    section.add "X-Amz-Date", valid_614871
  var valid_614872 = header.getOrDefault("X-Amz-Credential")
  valid_614872 = validateParameter(valid_614872, JString, required = false,
                                 default = nil)
  if valid_614872 != nil:
    section.add "X-Amz-Credential", valid_614872
  var valid_614873 = header.getOrDefault("X-Amz-Security-Token")
  valid_614873 = validateParameter(valid_614873, JString, required = false,
                                 default = nil)
  if valid_614873 != nil:
    section.add "X-Amz-Security-Token", valid_614873
  var valid_614874 = header.getOrDefault("X-Amz-Algorithm")
  valid_614874 = validateParameter(valid_614874, JString, required = false,
                                 default = nil)
  if valid_614874 != nil:
    section.add "X-Amz-Algorithm", valid_614874
  var valid_614875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614875 = validateParameter(valid_614875, JString, required = false,
                                 default = nil)
  if valid_614875 != nil:
    section.add "X-Amz-SignedHeaders", valid_614875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614876: Call_FlushStageAuthorizersCache_614864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_614876.validator(path, query, header, formData, body)
  let scheme = call_614876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614876.url(scheme.get, call_614876.host, call_614876.base,
                         call_614876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614876, url, valid)

proc call*(call_614877: Call_FlushStageAuthorizersCache_614864; restapiId: string;
          stageName: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  var path_614878 = newJObject()
  add(path_614878, "restapi_id", newJString(restapiId))
  add(path_614878, "stage_name", newJString(stageName))
  result = call_614877.call(path_614878, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_614864(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_614865, base: "/",
    url: url_FlushStageAuthorizersCache_614866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_614879 = ref object of OpenApiRestCall_612642
proc url_FlushStageCache_614881(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "stage_name" in path, "`stage_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stage_name"),
               (kind: ConstantSegment, value: "/cache/data")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FlushStageCache_614880(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Flushes a stage's cache.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the stage to flush its cache.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614882 = path.getOrDefault("restapi_id")
  valid_614882 = validateParameter(valid_614882, JString, required = true,
                                 default = nil)
  if valid_614882 != nil:
    section.add "restapi_id", valid_614882
  var valid_614883 = path.getOrDefault("stage_name")
  valid_614883 = validateParameter(valid_614883, JString, required = true,
                                 default = nil)
  if valid_614883 != nil:
    section.add "stage_name", valid_614883
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
  var valid_614884 = header.getOrDefault("X-Amz-Signature")
  valid_614884 = validateParameter(valid_614884, JString, required = false,
                                 default = nil)
  if valid_614884 != nil:
    section.add "X-Amz-Signature", valid_614884
  var valid_614885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614885 = validateParameter(valid_614885, JString, required = false,
                                 default = nil)
  if valid_614885 != nil:
    section.add "X-Amz-Content-Sha256", valid_614885
  var valid_614886 = header.getOrDefault("X-Amz-Date")
  valid_614886 = validateParameter(valid_614886, JString, required = false,
                                 default = nil)
  if valid_614886 != nil:
    section.add "X-Amz-Date", valid_614886
  var valid_614887 = header.getOrDefault("X-Amz-Credential")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "X-Amz-Credential", valid_614887
  var valid_614888 = header.getOrDefault("X-Amz-Security-Token")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "X-Amz-Security-Token", valid_614888
  var valid_614889 = header.getOrDefault("X-Amz-Algorithm")
  valid_614889 = validateParameter(valid_614889, JString, required = false,
                                 default = nil)
  if valid_614889 != nil:
    section.add "X-Amz-Algorithm", valid_614889
  var valid_614890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614890 = validateParameter(valid_614890, JString, required = false,
                                 default = nil)
  if valid_614890 != nil:
    section.add "X-Amz-SignedHeaders", valid_614890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614891: Call_FlushStageCache_614879; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_614891.validator(path, query, header, formData, body)
  let scheme = call_614891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614891.url(scheme.get, call_614891.host, call_614891.base,
                         call_614891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614891, url, valid)

proc call*(call_614892: Call_FlushStageCache_614879; restapiId: string;
          stageName: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  var path_614893 = newJObject()
  add(path_614893, "restapi_id", newJString(restapiId))
  add(path_614893, "stage_name", newJString(stageName))
  result = call_614892.call(path_614893, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_614879(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_614880, base: "/", url: url_FlushStageCache_614881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_614909 = ref object of OpenApiRestCall_612642
proc url_GenerateClientCertificate_614911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateClientCertificate_614910(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Generates a <a>ClientCertificate</a> resource.
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
  var valid_614912 = header.getOrDefault("X-Amz-Signature")
  valid_614912 = validateParameter(valid_614912, JString, required = false,
                                 default = nil)
  if valid_614912 != nil:
    section.add "X-Amz-Signature", valid_614912
  var valid_614913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614913 = validateParameter(valid_614913, JString, required = false,
                                 default = nil)
  if valid_614913 != nil:
    section.add "X-Amz-Content-Sha256", valid_614913
  var valid_614914 = header.getOrDefault("X-Amz-Date")
  valid_614914 = validateParameter(valid_614914, JString, required = false,
                                 default = nil)
  if valid_614914 != nil:
    section.add "X-Amz-Date", valid_614914
  var valid_614915 = header.getOrDefault("X-Amz-Credential")
  valid_614915 = validateParameter(valid_614915, JString, required = false,
                                 default = nil)
  if valid_614915 != nil:
    section.add "X-Amz-Credential", valid_614915
  var valid_614916 = header.getOrDefault("X-Amz-Security-Token")
  valid_614916 = validateParameter(valid_614916, JString, required = false,
                                 default = nil)
  if valid_614916 != nil:
    section.add "X-Amz-Security-Token", valid_614916
  var valid_614917 = header.getOrDefault("X-Amz-Algorithm")
  valid_614917 = validateParameter(valid_614917, JString, required = false,
                                 default = nil)
  if valid_614917 != nil:
    section.add "X-Amz-Algorithm", valid_614917
  var valid_614918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614918 = validateParameter(valid_614918, JString, required = false,
                                 default = nil)
  if valid_614918 != nil:
    section.add "X-Amz-SignedHeaders", valid_614918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614920: Call_GenerateClientCertificate_614909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_614920.validator(path, query, header, formData, body)
  let scheme = call_614920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614920.url(scheme.get, call_614920.host, call_614920.base,
                         call_614920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614920, url, valid)

proc call*(call_614921: Call_GenerateClientCertificate_614909; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_614922 = newJObject()
  if body != nil:
    body_614922 = body
  result = call_614921.call(nil, nil, nil, nil, body_614922)

var generateClientCertificate* = Call_GenerateClientCertificate_614909(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_614910, base: "/",
    url: url_GenerateClientCertificate_614911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_614894 = ref object of OpenApiRestCall_612642
proc url_GetClientCertificates_614896(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificates_614895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_614897 = query.getOrDefault("limit")
  valid_614897 = validateParameter(valid_614897, JInt, required = false, default = nil)
  if valid_614897 != nil:
    section.add "limit", valid_614897
  var valid_614898 = query.getOrDefault("position")
  valid_614898 = validateParameter(valid_614898, JString, required = false,
                                 default = nil)
  if valid_614898 != nil:
    section.add "position", valid_614898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614899 = header.getOrDefault("X-Amz-Signature")
  valid_614899 = validateParameter(valid_614899, JString, required = false,
                                 default = nil)
  if valid_614899 != nil:
    section.add "X-Amz-Signature", valid_614899
  var valid_614900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614900 = validateParameter(valid_614900, JString, required = false,
                                 default = nil)
  if valid_614900 != nil:
    section.add "X-Amz-Content-Sha256", valid_614900
  var valid_614901 = header.getOrDefault("X-Amz-Date")
  valid_614901 = validateParameter(valid_614901, JString, required = false,
                                 default = nil)
  if valid_614901 != nil:
    section.add "X-Amz-Date", valid_614901
  var valid_614902 = header.getOrDefault("X-Amz-Credential")
  valid_614902 = validateParameter(valid_614902, JString, required = false,
                                 default = nil)
  if valid_614902 != nil:
    section.add "X-Amz-Credential", valid_614902
  var valid_614903 = header.getOrDefault("X-Amz-Security-Token")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-Security-Token", valid_614903
  var valid_614904 = header.getOrDefault("X-Amz-Algorithm")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Algorithm", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-SignedHeaders", valid_614905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614906: Call_GetClientCertificates_614894; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_614906.validator(path, query, header, formData, body)
  let scheme = call_614906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614906.url(scheme.get, call_614906.host, call_614906.base,
                         call_614906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614906, url, valid)

proc call*(call_614907: Call_GetClientCertificates_614894; limit: int = 0;
          position: string = ""): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_614908 = newJObject()
  add(query_614908, "limit", newJInt(limit))
  add(query_614908, "position", newJString(position))
  result = call_614907.call(nil, query_614908, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_614894(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_614895, base: "/",
    url: url_GetClientCertificates_614896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_614923 = ref object of OpenApiRestCall_612642
proc url_GetAccount_614925(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_614924(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the current <a>Account</a> resource.
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
  var valid_614926 = header.getOrDefault("X-Amz-Signature")
  valid_614926 = validateParameter(valid_614926, JString, required = false,
                                 default = nil)
  if valid_614926 != nil:
    section.add "X-Amz-Signature", valid_614926
  var valid_614927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614927 = validateParameter(valid_614927, JString, required = false,
                                 default = nil)
  if valid_614927 != nil:
    section.add "X-Amz-Content-Sha256", valid_614927
  var valid_614928 = header.getOrDefault("X-Amz-Date")
  valid_614928 = validateParameter(valid_614928, JString, required = false,
                                 default = nil)
  if valid_614928 != nil:
    section.add "X-Amz-Date", valid_614928
  var valid_614929 = header.getOrDefault("X-Amz-Credential")
  valid_614929 = validateParameter(valid_614929, JString, required = false,
                                 default = nil)
  if valid_614929 != nil:
    section.add "X-Amz-Credential", valid_614929
  var valid_614930 = header.getOrDefault("X-Amz-Security-Token")
  valid_614930 = validateParameter(valid_614930, JString, required = false,
                                 default = nil)
  if valid_614930 != nil:
    section.add "X-Amz-Security-Token", valid_614930
  var valid_614931 = header.getOrDefault("X-Amz-Algorithm")
  valid_614931 = validateParameter(valid_614931, JString, required = false,
                                 default = nil)
  if valid_614931 != nil:
    section.add "X-Amz-Algorithm", valid_614931
  var valid_614932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614932 = validateParameter(valid_614932, JString, required = false,
                                 default = nil)
  if valid_614932 != nil:
    section.add "X-Amz-SignedHeaders", valid_614932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614933: Call_GetAccount_614923; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_614933.validator(path, query, header, formData, body)
  let scheme = call_614933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614933.url(scheme.get, call_614933.host, call_614933.base,
                         call_614933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614933, url, valid)

proc call*(call_614934: Call_GetAccount_614923): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_614934.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_614923(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_614924,
                                      base: "/", url: url_GetAccount_614925,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_614935 = ref object of OpenApiRestCall_612642
proc url_UpdateAccount_614937(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_614936(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about the current <a>Account</a> resource.
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
  var valid_614938 = header.getOrDefault("X-Amz-Signature")
  valid_614938 = validateParameter(valid_614938, JString, required = false,
                                 default = nil)
  if valid_614938 != nil:
    section.add "X-Amz-Signature", valid_614938
  var valid_614939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614939 = validateParameter(valid_614939, JString, required = false,
                                 default = nil)
  if valid_614939 != nil:
    section.add "X-Amz-Content-Sha256", valid_614939
  var valid_614940 = header.getOrDefault("X-Amz-Date")
  valid_614940 = validateParameter(valid_614940, JString, required = false,
                                 default = nil)
  if valid_614940 != nil:
    section.add "X-Amz-Date", valid_614940
  var valid_614941 = header.getOrDefault("X-Amz-Credential")
  valid_614941 = validateParameter(valid_614941, JString, required = false,
                                 default = nil)
  if valid_614941 != nil:
    section.add "X-Amz-Credential", valid_614941
  var valid_614942 = header.getOrDefault("X-Amz-Security-Token")
  valid_614942 = validateParameter(valid_614942, JString, required = false,
                                 default = nil)
  if valid_614942 != nil:
    section.add "X-Amz-Security-Token", valid_614942
  var valid_614943 = header.getOrDefault("X-Amz-Algorithm")
  valid_614943 = validateParameter(valid_614943, JString, required = false,
                                 default = nil)
  if valid_614943 != nil:
    section.add "X-Amz-Algorithm", valid_614943
  var valid_614944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614944 = validateParameter(valid_614944, JString, required = false,
                                 default = nil)
  if valid_614944 != nil:
    section.add "X-Amz-SignedHeaders", valid_614944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614946: Call_UpdateAccount_614935; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_614946.validator(path, query, header, formData, body)
  let scheme = call_614946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614946.url(scheme.get, call_614946.host, call_614946.base,
                         call_614946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614946, url, valid)

proc call*(call_614947: Call_UpdateAccount_614935; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_614948 = newJObject()
  if body != nil:
    body_614948 = body
  result = call_614947.call(nil, nil, nil, nil, body_614948)

var updateAccount* = Call_UpdateAccount_614935(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_614936, base: "/", url: url_UpdateAccount_614937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_614949 = ref object of OpenApiRestCall_612642
proc url_GetExport_614951(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "stage_name" in path, "`stage_name` is a required path parameter"
  assert "export_type" in path, "`export_type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stage_name"),
               (kind: ConstantSegment, value: "/exports/"),
               (kind: VariableSegment, value: "export_type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetExport_614950(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   export_type: JString (required)
  ##              : [Required] The type of export. Acceptable values are 'oas30' for OpenAPI 3.0.x and 'swagger' for Swagger/OpenAPI 2.0.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> that will be exported.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `export_type` field"
  var valid_614952 = path.getOrDefault("export_type")
  valid_614952 = validateParameter(valid_614952, JString, required = true,
                                 default = nil)
  if valid_614952 != nil:
    section.add "export_type", valid_614952
  var valid_614953 = path.getOrDefault("restapi_id")
  valid_614953 = validateParameter(valid_614953, JString, required = true,
                                 default = nil)
  if valid_614953 != nil:
    section.add "restapi_id", valid_614953
  var valid_614954 = path.getOrDefault("stage_name")
  valid_614954 = validateParameter(valid_614954, JString, required = true,
                                 default = nil)
  if valid_614954 != nil:
    section.add "stage_name", valid_614954
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_614955 = query.getOrDefault("parameters.2.value")
  valid_614955 = validateParameter(valid_614955, JString, required = false,
                                 default = nil)
  if valid_614955 != nil:
    section.add "parameters.2.value", valid_614955
  var valid_614956 = query.getOrDefault("parameters.1.value")
  valid_614956 = validateParameter(valid_614956, JString, required = false,
                                 default = nil)
  if valid_614956 != nil:
    section.add "parameters.1.value", valid_614956
  var valid_614957 = query.getOrDefault("parameters.1.key")
  valid_614957 = validateParameter(valid_614957, JString, required = false,
                                 default = nil)
  if valid_614957 != nil:
    section.add "parameters.1.key", valid_614957
  var valid_614958 = query.getOrDefault("parameters.2.key")
  valid_614958 = validateParameter(valid_614958, JString, required = false,
                                 default = nil)
  if valid_614958 != nil:
    section.add "parameters.2.key", valid_614958
  var valid_614959 = query.getOrDefault("parameters.0.value")
  valid_614959 = validateParameter(valid_614959, JString, required = false,
                                 default = nil)
  if valid_614959 != nil:
    section.add "parameters.0.value", valid_614959
  var valid_614960 = query.getOrDefault("parameters.0.key")
  valid_614960 = validateParameter(valid_614960, JString, required = false,
                                 default = nil)
  if valid_614960 != nil:
    section.add "parameters.0.key", valid_614960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   Accept: JString
  ##         : The content-type of the export, for example <code>application/json</code>. Currently <code>application/json</code> and <code>application/yaml</code> are supported for <code>exportType</code> of<code>oas30</code> and <code>swagger</code>. This should be specified in the <code>Accept</code> header for direct API requests.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614961 = header.getOrDefault("X-Amz-Signature")
  valid_614961 = validateParameter(valid_614961, JString, required = false,
                                 default = nil)
  if valid_614961 != nil:
    section.add "X-Amz-Signature", valid_614961
  var valid_614962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614962 = validateParameter(valid_614962, JString, required = false,
                                 default = nil)
  if valid_614962 != nil:
    section.add "X-Amz-Content-Sha256", valid_614962
  var valid_614963 = header.getOrDefault("X-Amz-Date")
  valid_614963 = validateParameter(valid_614963, JString, required = false,
                                 default = nil)
  if valid_614963 != nil:
    section.add "X-Amz-Date", valid_614963
  var valid_614964 = header.getOrDefault("X-Amz-Credential")
  valid_614964 = validateParameter(valid_614964, JString, required = false,
                                 default = nil)
  if valid_614964 != nil:
    section.add "X-Amz-Credential", valid_614964
  var valid_614965 = header.getOrDefault("X-Amz-Security-Token")
  valid_614965 = validateParameter(valid_614965, JString, required = false,
                                 default = nil)
  if valid_614965 != nil:
    section.add "X-Amz-Security-Token", valid_614965
  var valid_614966 = header.getOrDefault("X-Amz-Algorithm")
  valid_614966 = validateParameter(valid_614966, JString, required = false,
                                 default = nil)
  if valid_614966 != nil:
    section.add "X-Amz-Algorithm", valid_614966
  var valid_614967 = header.getOrDefault("Accept")
  valid_614967 = validateParameter(valid_614967, JString, required = false,
                                 default = nil)
  if valid_614967 != nil:
    section.add "Accept", valid_614967
  var valid_614968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614968 = validateParameter(valid_614968, JString, required = false,
                                 default = nil)
  if valid_614968 != nil:
    section.add "X-Amz-SignedHeaders", valid_614968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614969: Call_GetExport_614949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_614969.validator(path, query, header, formData, body)
  let scheme = call_614969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614969.url(scheme.get, call_614969.host, call_614969.base,
                         call_614969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614969, url, valid)

proc call*(call_614970: Call_GetExport_614949; exportType: string; restapiId: string;
          stageName: string; parameters2Value: string = "";
          parameters1Value: string = ""; parameters1Key: string = "";
          parameters2Key: string = ""; parameters0Value: string = "";
          parameters0Key: string = ""): Recallable =
  ## getExport
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ##   parameters2Value: string
  ##   parameters1Value: string
  ##   parameters1Key: string
  ##   exportType: string (required)
  ##             : [Required] The type of export. Acceptable values are 'oas30' for OpenAPI 3.0.x and 'swagger' for Swagger/OpenAPI 2.0.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   parameters2Key: string
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> that will be exported.
  ##   parameters0Value: string
  ##   parameters0Key: string
  var path_614971 = newJObject()
  var query_614972 = newJObject()
  add(query_614972, "parameters.2.value", newJString(parameters2Value))
  add(query_614972, "parameters.1.value", newJString(parameters1Value))
  add(query_614972, "parameters.1.key", newJString(parameters1Key))
  add(path_614971, "export_type", newJString(exportType))
  add(path_614971, "restapi_id", newJString(restapiId))
  add(query_614972, "parameters.2.key", newJString(parameters2Key))
  add(path_614971, "stage_name", newJString(stageName))
  add(query_614972, "parameters.0.value", newJString(parameters0Value))
  add(query_614972, "parameters.0.key", newJString(parameters0Key))
  result = call_614970.call(path_614971, query_614972, nil, nil, nil)

var getExport* = Call_GetExport_614949(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_614950,
                                    base: "/", url: url_GetExport_614951,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_614973 = ref object of OpenApiRestCall_612642
proc url_GetGatewayResponses_614975(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/gatewayresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGatewayResponses_614974(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_614976 = path.getOrDefault("restapi_id")
  valid_614976 = validateParameter(valid_614976, JString, required = true,
                                 default = nil)
  if valid_614976 != nil:
    section.add "restapi_id", valid_614976
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  section = newJObject()
  var valid_614977 = query.getOrDefault("limit")
  valid_614977 = validateParameter(valid_614977, JInt, required = false, default = nil)
  if valid_614977 != nil:
    section.add "limit", valid_614977
  var valid_614978 = query.getOrDefault("position")
  valid_614978 = validateParameter(valid_614978, JString, required = false,
                                 default = nil)
  if valid_614978 != nil:
    section.add "position", valid_614978
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614979 = header.getOrDefault("X-Amz-Signature")
  valid_614979 = validateParameter(valid_614979, JString, required = false,
                                 default = nil)
  if valid_614979 != nil:
    section.add "X-Amz-Signature", valid_614979
  var valid_614980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614980 = validateParameter(valid_614980, JString, required = false,
                                 default = nil)
  if valid_614980 != nil:
    section.add "X-Amz-Content-Sha256", valid_614980
  var valid_614981 = header.getOrDefault("X-Amz-Date")
  valid_614981 = validateParameter(valid_614981, JString, required = false,
                                 default = nil)
  if valid_614981 != nil:
    section.add "X-Amz-Date", valid_614981
  var valid_614982 = header.getOrDefault("X-Amz-Credential")
  valid_614982 = validateParameter(valid_614982, JString, required = false,
                                 default = nil)
  if valid_614982 != nil:
    section.add "X-Amz-Credential", valid_614982
  var valid_614983 = header.getOrDefault("X-Amz-Security-Token")
  valid_614983 = validateParameter(valid_614983, JString, required = false,
                                 default = nil)
  if valid_614983 != nil:
    section.add "X-Amz-Security-Token", valid_614983
  var valid_614984 = header.getOrDefault("X-Amz-Algorithm")
  valid_614984 = validateParameter(valid_614984, JString, required = false,
                                 default = nil)
  if valid_614984 != nil:
    section.add "X-Amz-Algorithm", valid_614984
  var valid_614985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614985 = validateParameter(valid_614985, JString, required = false,
                                 default = nil)
  if valid_614985 != nil:
    section.add "X-Amz-SignedHeaders", valid_614985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614986: Call_GetGatewayResponses_614973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_614986.validator(path, query, header, formData, body)
  let scheme = call_614986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614986.url(scheme.get, call_614986.host, call_614986.base,
                         call_614986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614986, url, valid)

proc call*(call_614987: Call_GetGatewayResponses_614973; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_614988 = newJObject()
  var query_614989 = newJObject()
  add(query_614989, "limit", newJInt(limit))
  add(query_614989, "position", newJString(position))
  add(path_614988, "restapi_id", newJString(restapiId))
  result = call_614987.call(path_614988, query_614989, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_614973(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_614974, base: "/",
    url: url_GetGatewayResponses_614975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_614990 = ref object of OpenApiRestCall_612642
proc url_GetModelTemplate_614992(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "model_name" in path, "`model_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "model_name"),
               (kind: ConstantSegment, value: "/default_template")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModelTemplate_614991(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   model_name: JString (required)
  ##             : [Required] The name of the model for which to generate a template.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `model_name` field"
  var valid_614993 = path.getOrDefault("model_name")
  valid_614993 = validateParameter(valid_614993, JString, required = true,
                                 default = nil)
  if valid_614993 != nil:
    section.add "model_name", valid_614993
  var valid_614994 = path.getOrDefault("restapi_id")
  valid_614994 = validateParameter(valid_614994, JString, required = true,
                                 default = nil)
  if valid_614994 != nil:
    section.add "restapi_id", valid_614994
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
  var valid_614995 = header.getOrDefault("X-Amz-Signature")
  valid_614995 = validateParameter(valid_614995, JString, required = false,
                                 default = nil)
  if valid_614995 != nil:
    section.add "X-Amz-Signature", valid_614995
  var valid_614996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614996 = validateParameter(valid_614996, JString, required = false,
                                 default = nil)
  if valid_614996 != nil:
    section.add "X-Amz-Content-Sha256", valid_614996
  var valid_614997 = header.getOrDefault("X-Amz-Date")
  valid_614997 = validateParameter(valid_614997, JString, required = false,
                                 default = nil)
  if valid_614997 != nil:
    section.add "X-Amz-Date", valid_614997
  var valid_614998 = header.getOrDefault("X-Amz-Credential")
  valid_614998 = validateParameter(valid_614998, JString, required = false,
                                 default = nil)
  if valid_614998 != nil:
    section.add "X-Amz-Credential", valid_614998
  var valid_614999 = header.getOrDefault("X-Amz-Security-Token")
  valid_614999 = validateParameter(valid_614999, JString, required = false,
                                 default = nil)
  if valid_614999 != nil:
    section.add "X-Amz-Security-Token", valid_614999
  var valid_615000 = header.getOrDefault("X-Amz-Algorithm")
  valid_615000 = validateParameter(valid_615000, JString, required = false,
                                 default = nil)
  if valid_615000 != nil:
    section.add "X-Amz-Algorithm", valid_615000
  var valid_615001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615001 = validateParameter(valid_615001, JString, required = false,
                                 default = nil)
  if valid_615001 != nil:
    section.add "X-Amz-SignedHeaders", valid_615001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615002: Call_GetModelTemplate_614990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_615002.validator(path, query, header, formData, body)
  let scheme = call_615002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615002.url(scheme.get, call_615002.host, call_615002.base,
                         call_615002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615002, url, valid)

proc call*(call_615003: Call_GetModelTemplate_614990; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_615004 = newJObject()
  add(path_615004, "model_name", newJString(modelName))
  add(path_615004, "restapi_id", newJString(restapiId))
  result = call_615003.call(path_615004, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_614990(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_614991, base: "/",
    url: url_GetModelTemplate_614992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_615005 = ref object of OpenApiRestCall_612642
proc url_GetResources_615007(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResources_615006(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_615008 = path.getOrDefault("restapi_id")
  valid_615008 = validateParameter(valid_615008, JString, required = true,
                                 default = nil)
  if valid_615008 != nil:
    section.add "restapi_id", valid_615008
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  section = newJObject()
  var valid_615009 = query.getOrDefault("limit")
  valid_615009 = validateParameter(valid_615009, JInt, required = false, default = nil)
  if valid_615009 != nil:
    section.add "limit", valid_615009
  var valid_615010 = query.getOrDefault("position")
  valid_615010 = validateParameter(valid_615010, JString, required = false,
                                 default = nil)
  if valid_615010 != nil:
    section.add "position", valid_615010
  var valid_615011 = query.getOrDefault("embed")
  valid_615011 = validateParameter(valid_615011, JArray, required = false,
                                 default = nil)
  if valid_615011 != nil:
    section.add "embed", valid_615011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615012 = header.getOrDefault("X-Amz-Signature")
  valid_615012 = validateParameter(valid_615012, JString, required = false,
                                 default = nil)
  if valid_615012 != nil:
    section.add "X-Amz-Signature", valid_615012
  var valid_615013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615013 = validateParameter(valid_615013, JString, required = false,
                                 default = nil)
  if valid_615013 != nil:
    section.add "X-Amz-Content-Sha256", valid_615013
  var valid_615014 = header.getOrDefault("X-Amz-Date")
  valid_615014 = validateParameter(valid_615014, JString, required = false,
                                 default = nil)
  if valid_615014 != nil:
    section.add "X-Amz-Date", valid_615014
  var valid_615015 = header.getOrDefault("X-Amz-Credential")
  valid_615015 = validateParameter(valid_615015, JString, required = false,
                                 default = nil)
  if valid_615015 != nil:
    section.add "X-Amz-Credential", valid_615015
  var valid_615016 = header.getOrDefault("X-Amz-Security-Token")
  valid_615016 = validateParameter(valid_615016, JString, required = false,
                                 default = nil)
  if valid_615016 != nil:
    section.add "X-Amz-Security-Token", valid_615016
  var valid_615017 = header.getOrDefault("X-Amz-Algorithm")
  valid_615017 = validateParameter(valid_615017, JString, required = false,
                                 default = nil)
  if valid_615017 != nil:
    section.add "X-Amz-Algorithm", valid_615017
  var valid_615018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615018 = validateParameter(valid_615018, JString, required = false,
                                 default = nil)
  if valid_615018 != nil:
    section.add "X-Amz-SignedHeaders", valid_615018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615019: Call_GetResources_615005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_615019.validator(path, query, header, formData, body)
  let scheme = call_615019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615019.url(scheme.get, call_615019.host, call_615019.base,
                         call_615019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615019, url, valid)

proc call*(call_615020: Call_GetResources_615005; restapiId: string; limit: int = 0;
          position: string = ""; embed: JsonNode = nil): Recallable =
  ## getResources
  ## Lists information about a collection of <a>Resource</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  var path_615021 = newJObject()
  var query_615022 = newJObject()
  add(query_615022, "limit", newJInt(limit))
  add(query_615022, "position", newJString(position))
  add(path_615021, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_615022.add "embed", embed
  result = call_615020.call(path_615021, query_615022, nil, nil, nil)

var getResources* = Call_GetResources_615005(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_615006,
    base: "/", url: url_GetResources_615007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_615023 = ref object of OpenApiRestCall_612642
proc url_GetSdk_615025(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  assert "stage_name" in path, "`stage_name` is a required path parameter"
  assert "sdk_type" in path, "`sdk_type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stage_name"),
               (kind: ConstantSegment, value: "/sdks/"),
               (kind: VariableSegment, value: "sdk_type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSdk_615024(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdk_type: JString (required)
  ##           : [Required] The language for the generated SDK. Currently <code>java</code>, <code>javascript</code>, <code>android</code>, <code>objectivec</code> (for iOS), <code>swift</code> (for iOS), and <code>ruby</code> are supported.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> that the SDK will use.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `sdk_type` field"
  var valid_615026 = path.getOrDefault("sdk_type")
  valid_615026 = validateParameter(valid_615026, JString, required = true,
                                 default = nil)
  if valid_615026 != nil:
    section.add "sdk_type", valid_615026
  var valid_615027 = path.getOrDefault("restapi_id")
  valid_615027 = validateParameter(valid_615027, JString, required = true,
                                 default = nil)
  if valid_615027 != nil:
    section.add "restapi_id", valid_615027
  var valid_615028 = path.getOrDefault("stage_name")
  valid_615028 = validateParameter(valid_615028, JString, required = true,
                                 default = nil)
  if valid_615028 != nil:
    section.add "stage_name", valid_615028
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_615029 = query.getOrDefault("parameters.2.value")
  valid_615029 = validateParameter(valid_615029, JString, required = false,
                                 default = nil)
  if valid_615029 != nil:
    section.add "parameters.2.value", valid_615029
  var valid_615030 = query.getOrDefault("parameters.1.value")
  valid_615030 = validateParameter(valid_615030, JString, required = false,
                                 default = nil)
  if valid_615030 != nil:
    section.add "parameters.1.value", valid_615030
  var valid_615031 = query.getOrDefault("parameters.1.key")
  valid_615031 = validateParameter(valid_615031, JString, required = false,
                                 default = nil)
  if valid_615031 != nil:
    section.add "parameters.1.key", valid_615031
  var valid_615032 = query.getOrDefault("parameters.2.key")
  valid_615032 = validateParameter(valid_615032, JString, required = false,
                                 default = nil)
  if valid_615032 != nil:
    section.add "parameters.2.key", valid_615032
  var valid_615033 = query.getOrDefault("parameters.0.value")
  valid_615033 = validateParameter(valid_615033, JString, required = false,
                                 default = nil)
  if valid_615033 != nil:
    section.add "parameters.0.value", valid_615033
  var valid_615034 = query.getOrDefault("parameters.0.key")
  valid_615034 = validateParameter(valid_615034, JString, required = false,
                                 default = nil)
  if valid_615034 != nil:
    section.add "parameters.0.key", valid_615034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615035 = header.getOrDefault("X-Amz-Signature")
  valid_615035 = validateParameter(valid_615035, JString, required = false,
                                 default = nil)
  if valid_615035 != nil:
    section.add "X-Amz-Signature", valid_615035
  var valid_615036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615036 = validateParameter(valid_615036, JString, required = false,
                                 default = nil)
  if valid_615036 != nil:
    section.add "X-Amz-Content-Sha256", valid_615036
  var valid_615037 = header.getOrDefault("X-Amz-Date")
  valid_615037 = validateParameter(valid_615037, JString, required = false,
                                 default = nil)
  if valid_615037 != nil:
    section.add "X-Amz-Date", valid_615037
  var valid_615038 = header.getOrDefault("X-Amz-Credential")
  valid_615038 = validateParameter(valid_615038, JString, required = false,
                                 default = nil)
  if valid_615038 != nil:
    section.add "X-Amz-Credential", valid_615038
  var valid_615039 = header.getOrDefault("X-Amz-Security-Token")
  valid_615039 = validateParameter(valid_615039, JString, required = false,
                                 default = nil)
  if valid_615039 != nil:
    section.add "X-Amz-Security-Token", valid_615039
  var valid_615040 = header.getOrDefault("X-Amz-Algorithm")
  valid_615040 = validateParameter(valid_615040, JString, required = false,
                                 default = nil)
  if valid_615040 != nil:
    section.add "X-Amz-Algorithm", valid_615040
  var valid_615041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615041 = validateParameter(valid_615041, JString, required = false,
                                 default = nil)
  if valid_615041 != nil:
    section.add "X-Amz-SignedHeaders", valid_615041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615042: Call_GetSdk_615023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_615042.validator(path, query, header, formData, body)
  let scheme = call_615042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615042.url(scheme.get, call_615042.host, call_615042.base,
                         call_615042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615042, url, valid)

proc call*(call_615043: Call_GetSdk_615023; sdkType: string; restapiId: string;
          stageName: string; parameters2Value: string = "";
          parameters1Value: string = ""; parameters1Key: string = "";
          parameters2Key: string = ""; parameters0Value: string = "";
          parameters0Key: string = ""): Recallable =
  ## getSdk
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ##   sdkType: string (required)
  ##          : [Required] The language for the generated SDK. Currently <code>java</code>, <code>javascript</code>, <code>android</code>, <code>objectivec</code> (for iOS), <code>swift</code> (for iOS), and <code>ruby</code> are supported.
  ##   parameters2Value: string
  ##   parameters1Value: string
  ##   parameters1Key: string
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   parameters2Key: string
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> that the SDK will use.
  ##   parameters0Value: string
  ##   parameters0Key: string
  var path_615044 = newJObject()
  var query_615045 = newJObject()
  add(path_615044, "sdk_type", newJString(sdkType))
  add(query_615045, "parameters.2.value", newJString(parameters2Value))
  add(query_615045, "parameters.1.value", newJString(parameters1Value))
  add(query_615045, "parameters.1.key", newJString(parameters1Key))
  add(path_615044, "restapi_id", newJString(restapiId))
  add(query_615045, "parameters.2.key", newJString(parameters2Key))
  add(path_615044, "stage_name", newJString(stageName))
  add(query_615045, "parameters.0.value", newJString(parameters0Value))
  add(query_615045, "parameters.0.key", newJString(parameters0Key))
  result = call_615043.call(path_615044, query_615045, nil, nil, nil)

var getSdk* = Call_GetSdk_615023(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_615024, base: "/",
                              url: url_GetSdk_615025,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_615046 = ref object of OpenApiRestCall_612642
proc url_GetSdkType_615048(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "sdktype_id" in path, "`sdktype_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/sdktypes/"),
               (kind: VariableSegment, value: "sdktype_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSdkType_615047(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_615049 = path.getOrDefault("sdktype_id")
  valid_615049 = validateParameter(valid_615049, JString, required = true,
                                 default = nil)
  if valid_615049 != nil:
    section.add "sdktype_id", valid_615049
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
  var valid_615050 = header.getOrDefault("X-Amz-Signature")
  valid_615050 = validateParameter(valid_615050, JString, required = false,
                                 default = nil)
  if valid_615050 != nil:
    section.add "X-Amz-Signature", valid_615050
  var valid_615051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615051 = validateParameter(valid_615051, JString, required = false,
                                 default = nil)
  if valid_615051 != nil:
    section.add "X-Amz-Content-Sha256", valid_615051
  var valid_615052 = header.getOrDefault("X-Amz-Date")
  valid_615052 = validateParameter(valid_615052, JString, required = false,
                                 default = nil)
  if valid_615052 != nil:
    section.add "X-Amz-Date", valid_615052
  var valid_615053 = header.getOrDefault("X-Amz-Credential")
  valid_615053 = validateParameter(valid_615053, JString, required = false,
                                 default = nil)
  if valid_615053 != nil:
    section.add "X-Amz-Credential", valid_615053
  var valid_615054 = header.getOrDefault("X-Amz-Security-Token")
  valid_615054 = validateParameter(valid_615054, JString, required = false,
                                 default = nil)
  if valid_615054 != nil:
    section.add "X-Amz-Security-Token", valid_615054
  var valid_615055 = header.getOrDefault("X-Amz-Algorithm")
  valid_615055 = validateParameter(valid_615055, JString, required = false,
                                 default = nil)
  if valid_615055 != nil:
    section.add "X-Amz-Algorithm", valid_615055
  var valid_615056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615056 = validateParameter(valid_615056, JString, required = false,
                                 default = nil)
  if valid_615056 != nil:
    section.add "X-Amz-SignedHeaders", valid_615056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615057: Call_GetSdkType_615046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615057.validator(path, query, header, formData, body)
  let scheme = call_615057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615057.url(scheme.get, call_615057.host, call_615057.base,
                         call_615057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615057, url, valid)

proc call*(call_615058: Call_GetSdkType_615046; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_615059 = newJObject()
  add(path_615059, "sdktype_id", newJString(sdktypeId))
  result = call_615058.call(path_615059, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_615046(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_615047,
                                      base: "/", url: url_GetSdkType_615048,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_615060 = ref object of OpenApiRestCall_612642
proc url_GetSdkTypes_615062(protocol: Scheme; host: string; base: string;
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

proc validate_GetSdkTypes_615061(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_615063 = query.getOrDefault("limit")
  valid_615063 = validateParameter(valid_615063, JInt, required = false, default = nil)
  if valid_615063 != nil:
    section.add "limit", valid_615063
  var valid_615064 = query.getOrDefault("position")
  valid_615064 = validateParameter(valid_615064, JString, required = false,
                                 default = nil)
  if valid_615064 != nil:
    section.add "position", valid_615064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615065 = header.getOrDefault("X-Amz-Signature")
  valid_615065 = validateParameter(valid_615065, JString, required = false,
                                 default = nil)
  if valid_615065 != nil:
    section.add "X-Amz-Signature", valid_615065
  var valid_615066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615066 = validateParameter(valid_615066, JString, required = false,
                                 default = nil)
  if valid_615066 != nil:
    section.add "X-Amz-Content-Sha256", valid_615066
  var valid_615067 = header.getOrDefault("X-Amz-Date")
  valid_615067 = validateParameter(valid_615067, JString, required = false,
                                 default = nil)
  if valid_615067 != nil:
    section.add "X-Amz-Date", valid_615067
  var valid_615068 = header.getOrDefault("X-Amz-Credential")
  valid_615068 = validateParameter(valid_615068, JString, required = false,
                                 default = nil)
  if valid_615068 != nil:
    section.add "X-Amz-Credential", valid_615068
  var valid_615069 = header.getOrDefault("X-Amz-Security-Token")
  valid_615069 = validateParameter(valid_615069, JString, required = false,
                                 default = nil)
  if valid_615069 != nil:
    section.add "X-Amz-Security-Token", valid_615069
  var valid_615070 = header.getOrDefault("X-Amz-Algorithm")
  valid_615070 = validateParameter(valid_615070, JString, required = false,
                                 default = nil)
  if valid_615070 != nil:
    section.add "X-Amz-Algorithm", valid_615070
  var valid_615071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615071 = validateParameter(valid_615071, JString, required = false,
                                 default = nil)
  if valid_615071 != nil:
    section.add "X-Amz-SignedHeaders", valid_615071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615072: Call_GetSdkTypes_615060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615072.validator(path, query, header, formData, body)
  let scheme = call_615072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615072.url(scheme.get, call_615072.host, call_615072.base,
                         call_615072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615072, url, valid)

proc call*(call_615073: Call_GetSdkTypes_615060; limit: int = 0; position: string = ""): Recallable =
  ## getSdkTypes
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_615074 = newJObject()
  add(query_615074, "limit", newJInt(limit))
  add(query_615074, "position", newJString(position))
  result = call_615073.call(nil, query_615074, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_615060(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_615061,
                                        base: "/", url: url_GetSdkTypes_615062,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_615092 = ref object of OpenApiRestCall_612642
proc url_TagResource_615094(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_615093(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates a tag on a given resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource_arn: JString (required)
  ##               : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource_arn` field"
  var valid_615095 = path.getOrDefault("resource_arn")
  valid_615095 = validateParameter(valid_615095, JString, required = true,
                                 default = nil)
  if valid_615095 != nil:
    section.add "resource_arn", valid_615095
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
  var valid_615096 = header.getOrDefault("X-Amz-Signature")
  valid_615096 = validateParameter(valid_615096, JString, required = false,
                                 default = nil)
  if valid_615096 != nil:
    section.add "X-Amz-Signature", valid_615096
  var valid_615097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615097 = validateParameter(valid_615097, JString, required = false,
                                 default = nil)
  if valid_615097 != nil:
    section.add "X-Amz-Content-Sha256", valid_615097
  var valid_615098 = header.getOrDefault("X-Amz-Date")
  valid_615098 = validateParameter(valid_615098, JString, required = false,
                                 default = nil)
  if valid_615098 != nil:
    section.add "X-Amz-Date", valid_615098
  var valid_615099 = header.getOrDefault("X-Amz-Credential")
  valid_615099 = validateParameter(valid_615099, JString, required = false,
                                 default = nil)
  if valid_615099 != nil:
    section.add "X-Amz-Credential", valid_615099
  var valid_615100 = header.getOrDefault("X-Amz-Security-Token")
  valid_615100 = validateParameter(valid_615100, JString, required = false,
                                 default = nil)
  if valid_615100 != nil:
    section.add "X-Amz-Security-Token", valid_615100
  var valid_615101 = header.getOrDefault("X-Amz-Algorithm")
  valid_615101 = validateParameter(valid_615101, JString, required = false,
                                 default = nil)
  if valid_615101 != nil:
    section.add "X-Amz-Algorithm", valid_615101
  var valid_615102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615102 = validateParameter(valid_615102, JString, required = false,
                                 default = nil)
  if valid_615102 != nil:
    section.add "X-Amz-SignedHeaders", valid_615102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615104: Call_TagResource_615092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_615104.validator(path, query, header, formData, body)
  let scheme = call_615104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615104.url(scheme.get, call_615104.host, call_615104.base,
                         call_615104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615104, url, valid)

proc call*(call_615105: Call_TagResource_615092; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_615106 = newJObject()
  var body_615107 = newJObject()
  add(path_615106, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_615107 = body
  result = call_615105.call(path_615106, nil, nil, nil, body_615107)

var tagResource* = Call_TagResource_615092(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_615093,
                                        base: "/", url: url_TagResource_615094,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_615075 = ref object of OpenApiRestCall_612642
proc url_GetTags_615077(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTags_615076(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource_arn: JString (required)
  ##               : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource_arn` field"
  var valid_615078 = path.getOrDefault("resource_arn")
  valid_615078 = validateParameter(valid_615078, JString, required = true,
                                 default = nil)
  if valid_615078 != nil:
    section.add "resource_arn", valid_615078
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  section = newJObject()
  var valid_615079 = query.getOrDefault("limit")
  valid_615079 = validateParameter(valid_615079, JInt, required = false, default = nil)
  if valid_615079 != nil:
    section.add "limit", valid_615079
  var valid_615080 = query.getOrDefault("position")
  valid_615080 = validateParameter(valid_615080, JString, required = false,
                                 default = nil)
  if valid_615080 != nil:
    section.add "position", valid_615080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615081 = header.getOrDefault("X-Amz-Signature")
  valid_615081 = validateParameter(valid_615081, JString, required = false,
                                 default = nil)
  if valid_615081 != nil:
    section.add "X-Amz-Signature", valid_615081
  var valid_615082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615082 = validateParameter(valid_615082, JString, required = false,
                                 default = nil)
  if valid_615082 != nil:
    section.add "X-Amz-Content-Sha256", valid_615082
  var valid_615083 = header.getOrDefault("X-Amz-Date")
  valid_615083 = validateParameter(valid_615083, JString, required = false,
                                 default = nil)
  if valid_615083 != nil:
    section.add "X-Amz-Date", valid_615083
  var valid_615084 = header.getOrDefault("X-Amz-Credential")
  valid_615084 = validateParameter(valid_615084, JString, required = false,
                                 default = nil)
  if valid_615084 != nil:
    section.add "X-Amz-Credential", valid_615084
  var valid_615085 = header.getOrDefault("X-Amz-Security-Token")
  valid_615085 = validateParameter(valid_615085, JString, required = false,
                                 default = nil)
  if valid_615085 != nil:
    section.add "X-Amz-Security-Token", valid_615085
  var valid_615086 = header.getOrDefault("X-Amz-Algorithm")
  valid_615086 = validateParameter(valid_615086, JString, required = false,
                                 default = nil)
  if valid_615086 != nil:
    section.add "X-Amz-Algorithm", valid_615086
  var valid_615087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615087 = validateParameter(valid_615087, JString, required = false,
                                 default = nil)
  if valid_615087 != nil:
    section.add "X-Amz-SignedHeaders", valid_615087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615088: Call_GetTags_615075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_615088.validator(path, query, header, formData, body)
  let scheme = call_615088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615088.url(scheme.get, call_615088.host, call_615088.base,
                         call_615088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615088, url, valid)

proc call*(call_615089: Call_GetTags_615075; resourceArn: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  var path_615090 = newJObject()
  var query_615091 = newJObject()
  add(query_615091, "limit", newJInt(limit))
  add(path_615090, "resource_arn", newJString(resourceArn))
  add(query_615091, "position", newJString(position))
  result = call_615089.call(path_615090, query_615091, nil, nil, nil)

var getTags* = Call_GetTags_615075(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_615076, base: "/",
                                url: url_GetTags_615077,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_615108 = ref object of OpenApiRestCall_612642
proc url_GetUsage_615110(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/usage#startDate&endDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsage_615109(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_615111 = path.getOrDefault("usageplanId")
  valid_615111 = validateParameter(valid_615111, JString, required = true,
                                 default = nil)
  if valid_615111 != nil:
    section.add "usageplanId", valid_615111
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   endDate: JString (required)
  ##          : [Required] The ending date (e.g., 2016-12-31) of the usage data.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   keyId: JString
  ##        : The Id of the API key associated with the resultant usage data.
  ##   startDate: JString (required)
  ##            : [Required] The starting date (e.g., 2016-01-01) of the usage data.
  section = newJObject()
  var valid_615112 = query.getOrDefault("limit")
  valid_615112 = validateParameter(valid_615112, JInt, required = false, default = nil)
  if valid_615112 != nil:
    section.add "limit", valid_615112
  assert query != nil, "query argument is necessary due to required `endDate` field"
  var valid_615113 = query.getOrDefault("endDate")
  valid_615113 = validateParameter(valid_615113, JString, required = true,
                                 default = nil)
  if valid_615113 != nil:
    section.add "endDate", valid_615113
  var valid_615114 = query.getOrDefault("position")
  valid_615114 = validateParameter(valid_615114, JString, required = false,
                                 default = nil)
  if valid_615114 != nil:
    section.add "position", valid_615114
  var valid_615115 = query.getOrDefault("keyId")
  valid_615115 = validateParameter(valid_615115, JString, required = false,
                                 default = nil)
  if valid_615115 != nil:
    section.add "keyId", valid_615115
  var valid_615116 = query.getOrDefault("startDate")
  valid_615116 = validateParameter(valid_615116, JString, required = true,
                                 default = nil)
  if valid_615116 != nil:
    section.add "startDate", valid_615116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615117 = header.getOrDefault("X-Amz-Signature")
  valid_615117 = validateParameter(valid_615117, JString, required = false,
                                 default = nil)
  if valid_615117 != nil:
    section.add "X-Amz-Signature", valid_615117
  var valid_615118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615118 = validateParameter(valid_615118, JString, required = false,
                                 default = nil)
  if valid_615118 != nil:
    section.add "X-Amz-Content-Sha256", valid_615118
  var valid_615119 = header.getOrDefault("X-Amz-Date")
  valid_615119 = validateParameter(valid_615119, JString, required = false,
                                 default = nil)
  if valid_615119 != nil:
    section.add "X-Amz-Date", valid_615119
  var valid_615120 = header.getOrDefault("X-Amz-Credential")
  valid_615120 = validateParameter(valid_615120, JString, required = false,
                                 default = nil)
  if valid_615120 != nil:
    section.add "X-Amz-Credential", valid_615120
  var valid_615121 = header.getOrDefault("X-Amz-Security-Token")
  valid_615121 = validateParameter(valid_615121, JString, required = false,
                                 default = nil)
  if valid_615121 != nil:
    section.add "X-Amz-Security-Token", valid_615121
  var valid_615122 = header.getOrDefault("X-Amz-Algorithm")
  valid_615122 = validateParameter(valid_615122, JString, required = false,
                                 default = nil)
  if valid_615122 != nil:
    section.add "X-Amz-Algorithm", valid_615122
  var valid_615123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615123 = validateParameter(valid_615123, JString, required = false,
                                 default = nil)
  if valid_615123 != nil:
    section.add "X-Amz-SignedHeaders", valid_615123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615124: Call_GetUsage_615108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_615124.validator(path, query, header, formData, body)
  let scheme = call_615124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615124.url(scheme.get, call_615124.host, call_615124.base,
                         call_615124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615124, url, valid)

proc call*(call_615125: Call_GetUsage_615108; usageplanId: string; endDate: string;
          startDate: string; limit: int = 0; position: string = ""; keyId: string = ""): Recallable =
  ## getUsage
  ## Gets the usage data of a usage plan in a specified time interval.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   endDate: string (required)
  ##          : [Required] The ending date (e.g., 2016-12-31) of the usage data.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   keyId: string
  ##        : The Id of the API key associated with the resultant usage data.
  ##   startDate: string (required)
  ##            : [Required] The starting date (e.g., 2016-01-01) of the usage data.
  var path_615126 = newJObject()
  var query_615127 = newJObject()
  add(path_615126, "usageplanId", newJString(usageplanId))
  add(query_615127, "limit", newJInt(limit))
  add(query_615127, "endDate", newJString(endDate))
  add(query_615127, "position", newJString(position))
  add(query_615127, "keyId", newJString(keyId))
  add(query_615127, "startDate", newJString(startDate))
  result = call_615125.call(path_615126, query_615127, nil, nil, nil)

var getUsage* = Call_GetUsage_615108(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_615109, base: "/",
                                  url: url_GetUsage_615110,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_615128 = ref object of OpenApiRestCall_612642
proc url_ImportApiKeys_615130(protocol: Scheme; host: string; base: string;
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

proc validate_ImportApiKeys_615129(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   mode: JString (required)
  ##   format: JString (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  section = newJObject()
  var valid_615131 = query.getOrDefault("failonwarnings")
  valid_615131 = validateParameter(valid_615131, JBool, required = false, default = nil)
  if valid_615131 != nil:
    section.add "failonwarnings", valid_615131
  var valid_615132 = query.getOrDefault("mode")
  valid_615132 = validateParameter(valid_615132, JString, required = true,
                                 default = newJString("import"))
  if valid_615132 != nil:
    section.add "mode", valid_615132
  var valid_615133 = query.getOrDefault("format")
  valid_615133 = validateParameter(valid_615133, JString, required = true,
                                 default = newJString("csv"))
  if valid_615133 != nil:
    section.add "format", valid_615133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615134 = header.getOrDefault("X-Amz-Signature")
  valid_615134 = validateParameter(valid_615134, JString, required = false,
                                 default = nil)
  if valid_615134 != nil:
    section.add "X-Amz-Signature", valid_615134
  var valid_615135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615135 = validateParameter(valid_615135, JString, required = false,
                                 default = nil)
  if valid_615135 != nil:
    section.add "X-Amz-Content-Sha256", valid_615135
  var valid_615136 = header.getOrDefault("X-Amz-Date")
  valid_615136 = validateParameter(valid_615136, JString, required = false,
                                 default = nil)
  if valid_615136 != nil:
    section.add "X-Amz-Date", valid_615136
  var valid_615137 = header.getOrDefault("X-Amz-Credential")
  valid_615137 = validateParameter(valid_615137, JString, required = false,
                                 default = nil)
  if valid_615137 != nil:
    section.add "X-Amz-Credential", valid_615137
  var valid_615138 = header.getOrDefault("X-Amz-Security-Token")
  valid_615138 = validateParameter(valid_615138, JString, required = false,
                                 default = nil)
  if valid_615138 != nil:
    section.add "X-Amz-Security-Token", valid_615138
  var valid_615139 = header.getOrDefault("X-Amz-Algorithm")
  valid_615139 = validateParameter(valid_615139, JString, required = false,
                                 default = nil)
  if valid_615139 != nil:
    section.add "X-Amz-Algorithm", valid_615139
  var valid_615140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615140 = validateParameter(valid_615140, JString, required = false,
                                 default = nil)
  if valid_615140 != nil:
    section.add "X-Amz-SignedHeaders", valid_615140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615142: Call_ImportApiKeys_615128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_615142.validator(path, query, header, formData, body)
  let scheme = call_615142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615142.url(scheme.get, call_615142.host, call_615142.base,
                         call_615142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615142, url, valid)

proc call*(call_615143: Call_ImportApiKeys_615128; body: JsonNode;
          failonwarnings: bool = false; mode: string = "import"; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   mode: string (required)
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_615144 = newJObject()
  var body_615145 = newJObject()
  add(query_615144, "failonwarnings", newJBool(failonwarnings))
  add(query_615144, "mode", newJString(mode))
  if body != nil:
    body_615145 = body
  add(query_615144, "format", newJString(format))
  result = call_615143.call(nil, query_615144, nil, nil, body_615145)

var importApiKeys* = Call_ImportApiKeys_615128(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_615129,
    base: "/", url: url_ImportApiKeys_615130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_615146 = ref object of OpenApiRestCall_612642
proc url_ImportRestApi_615148(protocol: Scheme; host: string; base: string;
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

proc validate_ImportRestApi_615147(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to indicate whether to rollback the API creation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   mode: JString (required)
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_615149 = query.getOrDefault("failonwarnings")
  valid_615149 = validateParameter(valid_615149, JBool, required = false, default = nil)
  if valid_615149 != nil:
    section.add "failonwarnings", valid_615149
  var valid_615150 = query.getOrDefault("parameters.2.value")
  valid_615150 = validateParameter(valid_615150, JString, required = false,
                                 default = nil)
  if valid_615150 != nil:
    section.add "parameters.2.value", valid_615150
  var valid_615151 = query.getOrDefault("parameters.1.value")
  valid_615151 = validateParameter(valid_615151, JString, required = false,
                                 default = nil)
  if valid_615151 != nil:
    section.add "parameters.1.value", valid_615151
  var valid_615152 = query.getOrDefault("mode")
  valid_615152 = validateParameter(valid_615152, JString, required = true,
                                 default = newJString("import"))
  if valid_615152 != nil:
    section.add "mode", valid_615152
  var valid_615153 = query.getOrDefault("parameters.1.key")
  valid_615153 = validateParameter(valid_615153, JString, required = false,
                                 default = nil)
  if valid_615153 != nil:
    section.add "parameters.1.key", valid_615153
  var valid_615154 = query.getOrDefault("parameters.2.key")
  valid_615154 = validateParameter(valid_615154, JString, required = false,
                                 default = nil)
  if valid_615154 != nil:
    section.add "parameters.2.key", valid_615154
  var valid_615155 = query.getOrDefault("parameters.0.value")
  valid_615155 = validateParameter(valid_615155, JString, required = false,
                                 default = nil)
  if valid_615155 != nil:
    section.add "parameters.0.value", valid_615155
  var valid_615156 = query.getOrDefault("parameters.0.key")
  valid_615156 = validateParameter(valid_615156, JString, required = false,
                                 default = nil)
  if valid_615156 != nil:
    section.add "parameters.0.key", valid_615156
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615157 = header.getOrDefault("X-Amz-Signature")
  valid_615157 = validateParameter(valid_615157, JString, required = false,
                                 default = nil)
  if valid_615157 != nil:
    section.add "X-Amz-Signature", valid_615157
  var valid_615158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615158 = validateParameter(valid_615158, JString, required = false,
                                 default = nil)
  if valid_615158 != nil:
    section.add "X-Amz-Content-Sha256", valid_615158
  var valid_615159 = header.getOrDefault("X-Amz-Date")
  valid_615159 = validateParameter(valid_615159, JString, required = false,
                                 default = nil)
  if valid_615159 != nil:
    section.add "X-Amz-Date", valid_615159
  var valid_615160 = header.getOrDefault("X-Amz-Credential")
  valid_615160 = validateParameter(valid_615160, JString, required = false,
                                 default = nil)
  if valid_615160 != nil:
    section.add "X-Amz-Credential", valid_615160
  var valid_615161 = header.getOrDefault("X-Amz-Security-Token")
  valid_615161 = validateParameter(valid_615161, JString, required = false,
                                 default = nil)
  if valid_615161 != nil:
    section.add "X-Amz-Security-Token", valid_615161
  var valid_615162 = header.getOrDefault("X-Amz-Algorithm")
  valid_615162 = validateParameter(valid_615162, JString, required = false,
                                 default = nil)
  if valid_615162 != nil:
    section.add "X-Amz-Algorithm", valid_615162
  var valid_615163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615163 = validateParameter(valid_615163, JString, required = false,
                                 default = nil)
  if valid_615163 != nil:
    section.add "X-Amz-SignedHeaders", valid_615163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615165: Call_ImportRestApi_615146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_615165.validator(path, query, header, formData, body)
  let scheme = call_615165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615165.url(scheme.get, call_615165.host, call_615165.base,
                         call_615165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615165, url, valid)

proc call*(call_615166: Call_ImportRestApi_615146; body: JsonNode;
          failonwarnings: bool = false; parameters2Value: string = "";
          parameters1Value: string = ""; mode: string = "import";
          parameters1Key: string = ""; parameters2Key: string = "";
          parameters0Value: string = ""; parameters0Key: string = ""): Recallable =
  ## importRestApi
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback the API creation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   parameters2Value: string
  ##   parameters1Value: string
  ##   mode: string (required)
  ##   parameters1Key: string
  ##   parameters2Key: string
  ##   body: JObject (required)
  ##   parameters0Value: string
  ##   parameters0Key: string
  var query_615167 = newJObject()
  var body_615168 = newJObject()
  add(query_615167, "failonwarnings", newJBool(failonwarnings))
  add(query_615167, "parameters.2.value", newJString(parameters2Value))
  add(query_615167, "parameters.1.value", newJString(parameters1Value))
  add(query_615167, "mode", newJString(mode))
  add(query_615167, "parameters.1.key", newJString(parameters1Key))
  add(query_615167, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_615168 = body
  add(query_615167, "parameters.0.value", newJString(parameters0Value))
  add(query_615167, "parameters.0.key", newJString(parameters0Key))
  result = call_615166.call(nil, query_615167, nil, nil, body_615168)

var importRestApi* = Call_ImportRestApi_615146(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_615147,
    base: "/", url: url_ImportRestApi_615148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_615169 = ref object of OpenApiRestCall_612642
proc url_UntagResource_615171(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn"),
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

proc validate_UntagResource_615170(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a tag from a given resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource_arn: JString (required)
  ##               : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource_arn` field"
  var valid_615172 = path.getOrDefault("resource_arn")
  valid_615172 = validateParameter(valid_615172, JString, required = true,
                                 default = nil)
  if valid_615172 != nil:
    section.add "resource_arn", valid_615172
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_615173 = query.getOrDefault("tagKeys")
  valid_615173 = validateParameter(valid_615173, JArray, required = true, default = nil)
  if valid_615173 != nil:
    section.add "tagKeys", valid_615173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_615174 = header.getOrDefault("X-Amz-Signature")
  valid_615174 = validateParameter(valid_615174, JString, required = false,
                                 default = nil)
  if valid_615174 != nil:
    section.add "X-Amz-Signature", valid_615174
  var valid_615175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615175 = validateParameter(valid_615175, JString, required = false,
                                 default = nil)
  if valid_615175 != nil:
    section.add "X-Amz-Content-Sha256", valid_615175
  var valid_615176 = header.getOrDefault("X-Amz-Date")
  valid_615176 = validateParameter(valid_615176, JString, required = false,
                                 default = nil)
  if valid_615176 != nil:
    section.add "X-Amz-Date", valid_615176
  var valid_615177 = header.getOrDefault("X-Amz-Credential")
  valid_615177 = validateParameter(valid_615177, JString, required = false,
                                 default = nil)
  if valid_615177 != nil:
    section.add "X-Amz-Credential", valid_615177
  var valid_615178 = header.getOrDefault("X-Amz-Security-Token")
  valid_615178 = validateParameter(valid_615178, JString, required = false,
                                 default = nil)
  if valid_615178 != nil:
    section.add "X-Amz-Security-Token", valid_615178
  var valid_615179 = header.getOrDefault("X-Amz-Algorithm")
  valid_615179 = validateParameter(valid_615179, JString, required = false,
                                 default = nil)
  if valid_615179 != nil:
    section.add "X-Amz-Algorithm", valid_615179
  var valid_615180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615180 = validateParameter(valid_615180, JString, required = false,
                                 default = nil)
  if valid_615180 != nil:
    section.add "X-Amz-SignedHeaders", valid_615180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615181: Call_UntagResource_615169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_615181.validator(path, query, header, formData, body)
  let scheme = call_615181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615181.url(scheme.get, call_615181.host, call_615181.base,
                         call_615181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615181, url, valid)

proc call*(call_615182: Call_UntagResource_615169; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_615183 = newJObject()
  var query_615184 = newJObject()
  add(path_615183, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_615184.add "tagKeys", tagKeys
  result = call_615182.call(path_615183, query_615184, nil, nil, nil)

var untagResource* = Call_UntagResource_615169(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_615170,
    base: "/", url: url_UntagResource_615171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_615185 = ref object of OpenApiRestCall_612642
proc url_UpdateUsage_615187(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  assert "keyId" in path, "`keyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/keys/"),
               (kind: VariableSegment, value: "keyId"),
               (kind: ConstantSegment, value: "/usage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUsage_615186(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   keyId: JString (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `usageplanId` field"
  var valid_615188 = path.getOrDefault("usageplanId")
  valid_615188 = validateParameter(valid_615188, JString, required = true,
                                 default = nil)
  if valid_615188 != nil:
    section.add "usageplanId", valid_615188
  var valid_615189 = path.getOrDefault("keyId")
  valid_615189 = validateParameter(valid_615189, JString, required = true,
                                 default = nil)
  if valid_615189 != nil:
    section.add "keyId", valid_615189
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
  var valid_615190 = header.getOrDefault("X-Amz-Signature")
  valid_615190 = validateParameter(valid_615190, JString, required = false,
                                 default = nil)
  if valid_615190 != nil:
    section.add "X-Amz-Signature", valid_615190
  var valid_615191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615191 = validateParameter(valid_615191, JString, required = false,
                                 default = nil)
  if valid_615191 != nil:
    section.add "X-Amz-Content-Sha256", valid_615191
  var valid_615192 = header.getOrDefault("X-Amz-Date")
  valid_615192 = validateParameter(valid_615192, JString, required = false,
                                 default = nil)
  if valid_615192 != nil:
    section.add "X-Amz-Date", valid_615192
  var valid_615193 = header.getOrDefault("X-Amz-Credential")
  valid_615193 = validateParameter(valid_615193, JString, required = false,
                                 default = nil)
  if valid_615193 != nil:
    section.add "X-Amz-Credential", valid_615193
  var valid_615194 = header.getOrDefault("X-Amz-Security-Token")
  valid_615194 = validateParameter(valid_615194, JString, required = false,
                                 default = nil)
  if valid_615194 != nil:
    section.add "X-Amz-Security-Token", valid_615194
  var valid_615195 = header.getOrDefault("X-Amz-Algorithm")
  valid_615195 = validateParameter(valid_615195, JString, required = false,
                                 default = nil)
  if valid_615195 != nil:
    section.add "X-Amz-Algorithm", valid_615195
  var valid_615196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615196 = validateParameter(valid_615196, JString, required = false,
                                 default = nil)
  if valid_615196 != nil:
    section.add "X-Amz-SignedHeaders", valid_615196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615198: Call_UpdateUsage_615185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_615198.validator(path, query, header, formData, body)
  let scheme = call_615198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615198.url(scheme.get, call_615198.host, call_615198.base,
                         call_615198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615198, url, valid)

proc call*(call_615199: Call_UpdateUsage_615185; usageplanId: string; keyId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   body: JObject (required)
  var path_615200 = newJObject()
  var body_615201 = newJObject()
  add(path_615200, "usageplanId", newJString(usageplanId))
  add(path_615200, "keyId", newJString(keyId))
  if body != nil:
    body_615201 = body
  result = call_615199.call(path_615200, nil, nil, nil, body_615201)

var updateUsage* = Call_UpdateUsage_615185(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_615186,
                                        base: "/", url: url_UpdateUsage_615187,
                                        schemes: {Scheme.Https, Scheme.Http})
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
