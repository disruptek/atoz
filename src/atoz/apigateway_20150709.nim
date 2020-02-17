
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
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
  awsServiceName = "apigateway"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_611240 = ref object of OpenApiRestCall_610642
proc url_CreateApiKey_611242(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApiKey_611241(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611243 = header.getOrDefault("X-Amz-Signature")
  valid_611243 = validateParameter(valid_611243, JString, required = false,
                                 default = nil)
  if valid_611243 != nil:
    section.add "X-Amz-Signature", valid_611243
  var valid_611244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611244 = validateParameter(valid_611244, JString, required = false,
                                 default = nil)
  if valid_611244 != nil:
    section.add "X-Amz-Content-Sha256", valid_611244
  var valid_611245 = header.getOrDefault("X-Amz-Date")
  valid_611245 = validateParameter(valid_611245, JString, required = false,
                                 default = nil)
  if valid_611245 != nil:
    section.add "X-Amz-Date", valid_611245
  var valid_611246 = header.getOrDefault("X-Amz-Credential")
  valid_611246 = validateParameter(valid_611246, JString, required = false,
                                 default = nil)
  if valid_611246 != nil:
    section.add "X-Amz-Credential", valid_611246
  var valid_611247 = header.getOrDefault("X-Amz-Security-Token")
  valid_611247 = validateParameter(valid_611247, JString, required = false,
                                 default = nil)
  if valid_611247 != nil:
    section.add "X-Amz-Security-Token", valid_611247
  var valid_611248 = header.getOrDefault("X-Amz-Algorithm")
  valid_611248 = validateParameter(valid_611248, JString, required = false,
                                 default = nil)
  if valid_611248 != nil:
    section.add "X-Amz-Algorithm", valid_611248
  var valid_611249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611249 = validateParameter(valid_611249, JString, required = false,
                                 default = nil)
  if valid_611249 != nil:
    section.add "X-Amz-SignedHeaders", valid_611249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611251: Call_CreateApiKey_611240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_611251.validator(path, query, header, formData, body)
  let scheme = call_611251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611251.url(scheme.get, call_611251.host, call_611251.base,
                         call_611251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611251, url, valid)

proc call*(call_611252: Call_CreateApiKey_611240; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_611253 = newJObject()
  if body != nil:
    body_611253 = body
  result = call_611252.call(nil, nil, nil, nil, body_611253)

var createApiKey* = Call_CreateApiKey_611240(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_611241, base: "/", url: url_CreateApiKey_611242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_610980 = ref object of OpenApiRestCall_610642
proc url_GetApiKeys_610982(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApiKeys_610981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611094 = query.getOrDefault("name")
  valid_611094 = validateParameter(valid_611094, JString, required = false,
                                 default = nil)
  if valid_611094 != nil:
    section.add "name", valid_611094
  var valid_611095 = query.getOrDefault("limit")
  valid_611095 = validateParameter(valid_611095, JInt, required = false, default = nil)
  if valid_611095 != nil:
    section.add "limit", valid_611095
  var valid_611096 = query.getOrDefault("position")
  valid_611096 = validateParameter(valid_611096, JString, required = false,
                                 default = nil)
  if valid_611096 != nil:
    section.add "position", valid_611096
  var valid_611097 = query.getOrDefault("includeValues")
  valid_611097 = validateParameter(valid_611097, JBool, required = false, default = nil)
  if valid_611097 != nil:
    section.add "includeValues", valid_611097
  var valid_611098 = query.getOrDefault("customerId")
  valid_611098 = validateParameter(valid_611098, JString, required = false,
                                 default = nil)
  if valid_611098 != nil:
    section.add "customerId", valid_611098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611099 = header.getOrDefault("X-Amz-Signature")
  valid_611099 = validateParameter(valid_611099, JString, required = false,
                                 default = nil)
  if valid_611099 != nil:
    section.add "X-Amz-Signature", valid_611099
  var valid_611100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611100 = validateParameter(valid_611100, JString, required = false,
                                 default = nil)
  if valid_611100 != nil:
    section.add "X-Amz-Content-Sha256", valid_611100
  var valid_611101 = header.getOrDefault("X-Amz-Date")
  valid_611101 = validateParameter(valid_611101, JString, required = false,
                                 default = nil)
  if valid_611101 != nil:
    section.add "X-Amz-Date", valid_611101
  var valid_611102 = header.getOrDefault("X-Amz-Credential")
  valid_611102 = validateParameter(valid_611102, JString, required = false,
                                 default = nil)
  if valid_611102 != nil:
    section.add "X-Amz-Credential", valid_611102
  var valid_611103 = header.getOrDefault("X-Amz-Security-Token")
  valid_611103 = validateParameter(valid_611103, JString, required = false,
                                 default = nil)
  if valid_611103 != nil:
    section.add "X-Amz-Security-Token", valid_611103
  var valid_611104 = header.getOrDefault("X-Amz-Algorithm")
  valid_611104 = validateParameter(valid_611104, JString, required = false,
                                 default = nil)
  if valid_611104 != nil:
    section.add "X-Amz-Algorithm", valid_611104
  var valid_611105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611105 = validateParameter(valid_611105, JString, required = false,
                                 default = nil)
  if valid_611105 != nil:
    section.add "X-Amz-SignedHeaders", valid_611105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611128: Call_GetApiKeys_610980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_611128.validator(path, query, header, formData, body)
  let scheme = call_611128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611128.url(scheme.get, call_611128.host, call_611128.base,
                         call_611128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611128, url, valid)

proc call*(call_611199: Call_GetApiKeys_610980; name: string = ""; limit: int = 0;
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
  var query_611200 = newJObject()
  add(query_611200, "name", newJString(name))
  add(query_611200, "limit", newJInt(limit))
  add(query_611200, "position", newJString(position))
  add(query_611200, "includeValues", newJBool(includeValues))
  add(query_611200, "customerId", newJString(customerId))
  result = call_611199.call(nil, query_611200, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_610980(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_610981,
                                      base: "/", url: url_GetApiKeys_610982,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_611285 = ref object of OpenApiRestCall_610642
proc url_CreateAuthorizer_611287(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAuthorizer_611286(path: JsonNode; query: JsonNode;
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
  var valid_611288 = path.getOrDefault("restapi_id")
  valid_611288 = validateParameter(valid_611288, JString, required = true,
                                 default = nil)
  if valid_611288 != nil:
    section.add "restapi_id", valid_611288
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611289 = header.getOrDefault("X-Amz-Signature")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Signature", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Content-Sha256", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Date")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Date", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Credential")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Credential", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Security-Token")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Security-Token", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Algorithm")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Algorithm", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-SignedHeaders", valid_611295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611297: Call_CreateAuthorizer_611285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_611297.validator(path, query, header, formData, body)
  let scheme = call_611297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611297.url(scheme.get, call_611297.host, call_611297.base,
                         call_611297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611297, url, valid)

proc call*(call_611298: Call_CreateAuthorizer_611285; restapiId: string;
          body: JsonNode): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611299 = newJObject()
  var body_611300 = newJObject()
  add(path_611299, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611300 = body
  result = call_611298.call(path_611299, nil, nil, nil, body_611300)

var createAuthorizer* = Call_CreateAuthorizer_611285(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_611286, base: "/",
    url: url_CreateAuthorizer_611287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_611254 = ref object of OpenApiRestCall_610642
proc url_GetAuthorizers_611256(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizers_611255(path: JsonNode; query: JsonNode;
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
  var valid_611271 = path.getOrDefault("restapi_id")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = nil)
  if valid_611271 != nil:
    section.add "restapi_id", valid_611271
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_611272 = query.getOrDefault("limit")
  valid_611272 = validateParameter(valid_611272, JInt, required = false, default = nil)
  if valid_611272 != nil:
    section.add "limit", valid_611272
  var valid_611273 = query.getOrDefault("position")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "position", valid_611273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611274 = header.getOrDefault("X-Amz-Signature")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Signature", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Content-Sha256", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Date")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Date", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Credential")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Credential", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Security-Token")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Security-Token", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Algorithm")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Algorithm", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-SignedHeaders", valid_611280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611281: Call_GetAuthorizers_611254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_611281.validator(path, query, header, formData, body)
  let scheme = call_611281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611281.url(scheme.get, call_611281.host, call_611281.base,
                         call_611281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611281, url, valid)

proc call*(call_611282: Call_GetAuthorizers_611254; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_611283 = newJObject()
  var query_611284 = newJObject()
  add(query_611284, "limit", newJInt(limit))
  add(query_611284, "position", newJString(position))
  add(path_611283, "restapi_id", newJString(restapiId))
  result = call_611282.call(path_611283, query_611284, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_611254(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_611255, base: "/", url: url_GetAuthorizers_611256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_611318 = ref object of OpenApiRestCall_610642
proc url_CreateBasePathMapping_611320(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBasePathMapping_611319(path: JsonNode; query: JsonNode;
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
  var valid_611321 = path.getOrDefault("domain_name")
  valid_611321 = validateParameter(valid_611321, JString, required = true,
                                 default = nil)
  if valid_611321 != nil:
    section.add "domain_name", valid_611321
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611322 = header.getOrDefault("X-Amz-Signature")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Signature", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Content-Sha256", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Date")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Date", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Credential")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Credential", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Security-Token")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Security-Token", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Algorithm")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Algorithm", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-SignedHeaders", valid_611328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611330: Call_CreateBasePathMapping_611318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_611330.validator(path, query, header, formData, body)
  let scheme = call_611330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611330.url(scheme.get, call_611330.host, call_611330.base,
                         call_611330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611330, url, valid)

proc call*(call_611331: Call_CreateBasePathMapping_611318; body: JsonNode;
          domainName: string): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  var path_611332 = newJObject()
  var body_611333 = newJObject()
  if body != nil:
    body_611333 = body
  add(path_611332, "domain_name", newJString(domainName))
  result = call_611331.call(path_611332, nil, nil, nil, body_611333)

var createBasePathMapping* = Call_CreateBasePathMapping_611318(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_611319, base: "/",
    url: url_CreateBasePathMapping_611320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_611301 = ref object of OpenApiRestCall_610642
proc url_GetBasePathMappings_611303(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBasePathMappings_611302(path: JsonNode; query: JsonNode;
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
  var valid_611304 = path.getOrDefault("domain_name")
  valid_611304 = validateParameter(valid_611304, JString, required = true,
                                 default = nil)
  if valid_611304 != nil:
    section.add "domain_name", valid_611304
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_611305 = query.getOrDefault("limit")
  valid_611305 = validateParameter(valid_611305, JInt, required = false, default = nil)
  if valid_611305 != nil:
    section.add "limit", valid_611305
  var valid_611306 = query.getOrDefault("position")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "position", valid_611306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611307 = header.getOrDefault("X-Amz-Signature")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Signature", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Content-Sha256", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Date")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Date", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Credential")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Credential", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Security-Token")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Security-Token", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Algorithm")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Algorithm", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-SignedHeaders", valid_611313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611314: Call_GetBasePathMappings_611301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_611314.validator(path, query, header, formData, body)
  let scheme = call_611314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611314.url(scheme.get, call_611314.host, call_611314.base,
                         call_611314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611314, url, valid)

proc call*(call_611315: Call_GetBasePathMappings_611301; domainName: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  var path_611316 = newJObject()
  var query_611317 = newJObject()
  add(query_611317, "limit", newJInt(limit))
  add(query_611317, "position", newJString(position))
  add(path_611316, "domain_name", newJString(domainName))
  result = call_611315.call(path_611316, query_611317, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_611301(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_611302, base: "/",
    url: url_GetBasePathMappings_611303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_611351 = ref object of OpenApiRestCall_610642
proc url_CreateDeployment_611353(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_611352(path: JsonNode; query: JsonNode;
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
  var valid_611354 = path.getOrDefault("restapi_id")
  valid_611354 = validateParameter(valid_611354, JString, required = true,
                                 default = nil)
  if valid_611354 != nil:
    section.add "restapi_id", valid_611354
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611355 = header.getOrDefault("X-Amz-Signature")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Signature", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Content-Sha256", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Date")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Date", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Credential")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Credential", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Security-Token")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Security-Token", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Algorithm")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Algorithm", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-SignedHeaders", valid_611361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611363: Call_CreateDeployment_611351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_611363.validator(path, query, header, formData, body)
  let scheme = call_611363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611363.url(scheme.get, call_611363.host, call_611363.base,
                         call_611363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611363, url, valid)

proc call*(call_611364: Call_CreateDeployment_611351; restapiId: string;
          body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611365 = newJObject()
  var body_611366 = newJObject()
  add(path_611365, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611366 = body
  result = call_611364.call(path_611365, nil, nil, nil, body_611366)

var createDeployment* = Call_CreateDeployment_611351(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_611352, base: "/",
    url: url_CreateDeployment_611353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_611334 = ref object of OpenApiRestCall_610642
proc url_GetDeployments_611336(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployments_611335(path: JsonNode; query: JsonNode;
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
  var valid_611337 = path.getOrDefault("restapi_id")
  valid_611337 = validateParameter(valid_611337, JString, required = true,
                                 default = nil)
  if valid_611337 != nil:
    section.add "restapi_id", valid_611337
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_611338 = query.getOrDefault("limit")
  valid_611338 = validateParameter(valid_611338, JInt, required = false, default = nil)
  if valid_611338 != nil:
    section.add "limit", valid_611338
  var valid_611339 = query.getOrDefault("position")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "position", valid_611339
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611340 = header.getOrDefault("X-Amz-Signature")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Signature", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Content-Sha256", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Date")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Date", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Credential")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Credential", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Security-Token")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Security-Token", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Algorithm")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Algorithm", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-SignedHeaders", valid_611346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611347: Call_GetDeployments_611334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_611347.validator(path, query, header, formData, body)
  let scheme = call_611347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611347.url(scheme.get, call_611347.host, call_611347.base,
                         call_611347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611347, url, valid)

proc call*(call_611348: Call_GetDeployments_611334; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_611349 = newJObject()
  var query_611350 = newJObject()
  add(query_611350, "limit", newJInt(limit))
  add(query_611350, "position", newJString(position))
  add(path_611349, "restapi_id", newJString(restapiId))
  result = call_611348.call(path_611349, query_611350, nil, nil, nil)

var getDeployments* = Call_GetDeployments_611334(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_611335, base: "/", url: url_GetDeployments_611336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_611401 = ref object of OpenApiRestCall_610642
proc url_ImportDocumentationParts_611403(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ImportDocumentationParts_611402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_611404 = path.getOrDefault("restapi_id")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = nil)
  if valid_611404 != nil:
    section.add "restapi_id", valid_611404
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  section = newJObject()
  var valid_611405 = query.getOrDefault("failonwarnings")
  valid_611405 = validateParameter(valid_611405, JBool, required = false, default = nil)
  if valid_611405 != nil:
    section.add "failonwarnings", valid_611405
  var valid_611406 = query.getOrDefault("mode")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = newJString("merge"))
  if valid_611406 != nil:
    section.add "mode", valid_611406
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611407 = header.getOrDefault("X-Amz-Signature")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Signature", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Content-Sha256", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Date")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Date", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Credential")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Credential", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Security-Token")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Security-Token", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Algorithm")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Algorithm", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-SignedHeaders", valid_611413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611415: Call_ImportDocumentationParts_611401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611415.validator(path, query, header, formData, body)
  let scheme = call_611415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611415.url(scheme.get, call_611415.host, call_611415.base,
                         call_611415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611415, url, valid)

proc call*(call_611416: Call_ImportDocumentationParts_611401; restapiId: string;
          body: JsonNode; failonwarnings: bool = false; mode: string = "merge"): Recallable =
  ## importDocumentationParts
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611417 = newJObject()
  var query_611418 = newJObject()
  var body_611419 = newJObject()
  add(query_611418, "failonwarnings", newJBool(failonwarnings))
  add(query_611418, "mode", newJString(mode))
  add(path_611417, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611419 = body
  result = call_611416.call(path_611417, query_611418, nil, nil, body_611419)

var importDocumentationParts* = Call_ImportDocumentationParts_611401(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_611402, base: "/",
    url: url_ImportDocumentationParts_611403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_611420 = ref object of OpenApiRestCall_610642
proc url_CreateDocumentationPart_611422(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDocumentationPart_611421(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_611423 = path.getOrDefault("restapi_id")
  valid_611423 = validateParameter(valid_611423, JString, required = true,
                                 default = nil)
  if valid_611423 != nil:
    section.add "restapi_id", valid_611423
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611424 = header.getOrDefault("X-Amz-Signature")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Signature", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Content-Sha256", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Date")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Date", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Credential")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Credential", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Security-Token")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Security-Token", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Algorithm")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Algorithm", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-SignedHeaders", valid_611430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611432: Call_CreateDocumentationPart_611420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611432.validator(path, query, header, formData, body)
  let scheme = call_611432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611432.url(scheme.get, call_611432.host, call_611432.base,
                         call_611432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611432, url, valid)

proc call*(call_611433: Call_CreateDocumentationPart_611420; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationPart
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611434 = newJObject()
  var body_611435 = newJObject()
  add(path_611434, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611435 = body
  result = call_611433.call(path_611434, nil, nil, nil, body_611435)

var createDocumentationPart* = Call_CreateDocumentationPart_611420(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_611421, base: "/",
    url: url_CreateDocumentationPart_611422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_611367 = ref object of OpenApiRestCall_610642
proc url_GetDocumentationParts_611369(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationParts_611368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_611370 = path.getOrDefault("restapi_id")
  valid_611370 = validateParameter(valid_611370, JString, required = true,
                                 default = nil)
  if valid_611370 != nil:
    section.add "restapi_id", valid_611370
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
  var valid_611371 = query.getOrDefault("name")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "name", valid_611371
  var valid_611372 = query.getOrDefault("limit")
  valid_611372 = validateParameter(valid_611372, JInt, required = false, default = nil)
  if valid_611372 != nil:
    section.add "limit", valid_611372
  var valid_611386 = query.getOrDefault("locationStatus")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_611386 != nil:
    section.add "locationStatus", valid_611386
  var valid_611387 = query.getOrDefault("path")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "path", valid_611387
  var valid_611388 = query.getOrDefault("position")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "position", valid_611388
  var valid_611389 = query.getOrDefault("type")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = newJString("API"))
  if valid_611389 != nil:
    section.add "type", valid_611389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611390 = header.getOrDefault("X-Amz-Signature")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Signature", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Content-Sha256", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Date")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Date", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Credential")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Credential", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Security-Token")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Security-Token", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Algorithm")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Algorithm", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-SignedHeaders", valid_611396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_GetDocumentationParts_611367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_GetDocumentationParts_611367; restapiId: string;
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
  var path_611399 = newJObject()
  var query_611400 = newJObject()
  add(query_611400, "name", newJString(name))
  add(query_611400, "limit", newJInt(limit))
  add(query_611400, "locationStatus", newJString(locationStatus))
  add(query_611400, "path", newJString(path))
  add(query_611400, "position", newJString(position))
  add(query_611400, "type", newJString(`type`))
  add(path_611399, "restapi_id", newJString(restapiId))
  result = call_611398.call(path_611399, query_611400, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_611367(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_611368, base: "/",
    url: url_GetDocumentationParts_611369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_611453 = ref object of OpenApiRestCall_610642
proc url_CreateDocumentationVersion_611455(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDocumentationVersion_611454(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_611456 = path.getOrDefault("restapi_id")
  valid_611456 = validateParameter(valid_611456, JString, required = true,
                                 default = nil)
  if valid_611456 != nil:
    section.add "restapi_id", valid_611456
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611457 = header.getOrDefault("X-Amz-Signature")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Signature", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Content-Sha256", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Date")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Date", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Credential")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Credential", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Security-Token")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Security-Token", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Algorithm")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Algorithm", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-SignedHeaders", valid_611463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611465: Call_CreateDocumentationVersion_611453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611465.validator(path, query, header, formData, body)
  let scheme = call_611465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611465.url(scheme.get, call_611465.host, call_611465.base,
                         call_611465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611465, url, valid)

proc call*(call_611466: Call_CreateDocumentationVersion_611453; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationVersion
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611467 = newJObject()
  var body_611468 = newJObject()
  add(path_611467, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611468 = body
  result = call_611466.call(path_611467, nil, nil, nil, body_611468)

var createDocumentationVersion* = Call_CreateDocumentationVersion_611453(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_611454, base: "/",
    url: url_CreateDocumentationVersion_611455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_611436 = ref object of OpenApiRestCall_610642
proc url_GetDocumentationVersions_611438(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationVersions_611437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_611439 = path.getOrDefault("restapi_id")
  valid_611439 = validateParameter(valid_611439, JString, required = true,
                                 default = nil)
  if valid_611439 != nil:
    section.add "restapi_id", valid_611439
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_611440 = query.getOrDefault("limit")
  valid_611440 = validateParameter(valid_611440, JInt, required = false, default = nil)
  if valid_611440 != nil:
    section.add "limit", valid_611440
  var valid_611441 = query.getOrDefault("position")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "position", valid_611441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611442 = header.getOrDefault("X-Amz-Signature")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Signature", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Content-Sha256", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Date")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Date", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Credential")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Credential", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Security-Token")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Security-Token", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Algorithm")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Algorithm", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-SignedHeaders", valid_611448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611449: Call_GetDocumentationVersions_611436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611449.validator(path, query, header, formData, body)
  let scheme = call_611449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611449.url(scheme.get, call_611449.host, call_611449.base,
                         call_611449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611449, url, valid)

proc call*(call_611450: Call_GetDocumentationVersions_611436; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDocumentationVersions
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_611451 = newJObject()
  var query_611452 = newJObject()
  add(query_611452, "limit", newJInt(limit))
  add(query_611452, "position", newJString(position))
  add(path_611451, "restapi_id", newJString(restapiId))
  result = call_611450.call(path_611451, query_611452, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_611436(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_611437, base: "/",
    url: url_GetDocumentationVersions_611438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_611484 = ref object of OpenApiRestCall_610642
proc url_CreateDomainName_611486(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainName_611485(path: JsonNode; query: JsonNode;
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
  var valid_611487 = header.getOrDefault("X-Amz-Signature")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Signature", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Content-Sha256", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Date")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Date", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Credential")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Credential", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Security-Token")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Security-Token", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Algorithm")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Algorithm", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-SignedHeaders", valid_611493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611495: Call_CreateDomainName_611484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_611495.validator(path, query, header, formData, body)
  let scheme = call_611495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611495.url(scheme.get, call_611495.host, call_611495.base,
                         call_611495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611495, url, valid)

proc call*(call_611496: Call_CreateDomainName_611484; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_611497 = newJObject()
  if body != nil:
    body_611497 = body
  result = call_611496.call(nil, nil, nil, nil, body_611497)

var createDomainName* = Call_CreateDomainName_611484(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_611485, base: "/",
    url: url_CreateDomainName_611486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_611469 = ref object of OpenApiRestCall_610642
proc url_GetDomainNames_611471(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainNames_611470(path: JsonNode; query: JsonNode;
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
  var valid_611472 = query.getOrDefault("limit")
  valid_611472 = validateParameter(valid_611472, JInt, required = false, default = nil)
  if valid_611472 != nil:
    section.add "limit", valid_611472
  var valid_611473 = query.getOrDefault("position")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "position", valid_611473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611474 = header.getOrDefault("X-Amz-Signature")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Signature", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Content-Sha256", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Date")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Date", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Credential")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Credential", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Security-Token")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Security-Token", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Algorithm")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Algorithm", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-SignedHeaders", valid_611480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611481: Call_GetDomainNames_611469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_611481.validator(path, query, header, formData, body)
  let scheme = call_611481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611481.url(scheme.get, call_611481.host, call_611481.base,
                         call_611481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611481, url, valid)

proc call*(call_611482: Call_GetDomainNames_611469; limit: int = 0;
          position: string = ""): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_611483 = newJObject()
  add(query_611483, "limit", newJInt(limit))
  add(query_611483, "position", newJString(position))
  result = call_611482.call(nil, query_611483, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_611469(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_611470, base: "/",
    url: url_GetDomainNames_611471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_611515 = ref object of OpenApiRestCall_610642
proc url_CreateModel_611517(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateModel_611516(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611518 = path.getOrDefault("restapi_id")
  valid_611518 = validateParameter(valid_611518, JString, required = true,
                                 default = nil)
  if valid_611518 != nil:
    section.add "restapi_id", valid_611518
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611519 = header.getOrDefault("X-Amz-Signature")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Signature", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Content-Sha256", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Date")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Date", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Credential")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Credential", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Security-Token")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Security-Token", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Algorithm")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Algorithm", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-SignedHeaders", valid_611525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611527: Call_CreateModel_611515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_611527.validator(path, query, header, formData, body)
  let scheme = call_611527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611527.url(scheme.get, call_611527.host, call_611527.base,
                         call_611527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611527, url, valid)

proc call*(call_611528: Call_CreateModel_611515; restapiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  ##   body: JObject (required)
  var path_611529 = newJObject()
  var body_611530 = newJObject()
  add(path_611529, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611530 = body
  result = call_611528.call(path_611529, nil, nil, nil, body_611530)

var createModel* = Call_CreateModel_611515(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_611516,
                                        base: "/", url: url_CreateModel_611517,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_611498 = ref object of OpenApiRestCall_610642
proc url_GetModels_611500(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModels_611499(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611501 = path.getOrDefault("restapi_id")
  valid_611501 = validateParameter(valid_611501, JString, required = true,
                                 default = nil)
  if valid_611501 != nil:
    section.add "restapi_id", valid_611501
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_611502 = query.getOrDefault("limit")
  valid_611502 = validateParameter(valid_611502, JInt, required = false, default = nil)
  if valid_611502 != nil:
    section.add "limit", valid_611502
  var valid_611503 = query.getOrDefault("position")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "position", valid_611503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611504 = header.getOrDefault("X-Amz-Signature")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Signature", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Content-Sha256", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Date")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Date", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Credential")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Credential", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Security-Token")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Security-Token", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Algorithm")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Algorithm", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-SignedHeaders", valid_611510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611511: Call_GetModels_611498; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_611511.validator(path, query, header, formData, body)
  let scheme = call_611511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611511.url(scheme.get, call_611511.host, call_611511.base,
                         call_611511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611511, url, valid)

proc call*(call_611512: Call_GetModels_611498; restapiId: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_611513 = newJObject()
  var query_611514 = newJObject()
  add(query_611514, "limit", newJInt(limit))
  add(query_611514, "position", newJString(position))
  add(path_611513, "restapi_id", newJString(restapiId))
  result = call_611512.call(path_611513, query_611514, nil, nil, nil)

var getModels* = Call_GetModels_611498(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_611499,
                                    base: "/", url: url_GetModels_611500,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_611548 = ref object of OpenApiRestCall_610642
proc url_CreateRequestValidator_611550(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRequestValidator_611549(path: JsonNode; query: JsonNode;
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
  var valid_611551 = path.getOrDefault("restapi_id")
  valid_611551 = validateParameter(valid_611551, JString, required = true,
                                 default = nil)
  if valid_611551 != nil:
    section.add "restapi_id", valid_611551
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611552 = header.getOrDefault("X-Amz-Signature")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Signature", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Content-Sha256", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Date")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Date", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Credential")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Credential", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Security-Token")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Security-Token", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Algorithm")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Algorithm", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-SignedHeaders", valid_611558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611560: Call_CreateRequestValidator_611548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_611560.validator(path, query, header, formData, body)
  let scheme = call_611560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611560.url(scheme.get, call_611560.host, call_611560.base,
                         call_611560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611560, url, valid)

proc call*(call_611561: Call_CreateRequestValidator_611548; restapiId: string;
          body: JsonNode): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611562 = newJObject()
  var body_611563 = newJObject()
  add(path_611562, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611563 = body
  result = call_611561.call(path_611562, nil, nil, nil, body_611563)

var createRequestValidator* = Call_CreateRequestValidator_611548(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_611549, base: "/",
    url: url_CreateRequestValidator_611550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_611531 = ref object of OpenApiRestCall_610642
proc url_GetRequestValidators_611533(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRequestValidators_611532(path: JsonNode; query: JsonNode;
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
  var valid_611534 = path.getOrDefault("restapi_id")
  valid_611534 = validateParameter(valid_611534, JString, required = true,
                                 default = nil)
  if valid_611534 != nil:
    section.add "restapi_id", valid_611534
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_611535 = query.getOrDefault("limit")
  valid_611535 = validateParameter(valid_611535, JInt, required = false, default = nil)
  if valid_611535 != nil:
    section.add "limit", valid_611535
  var valid_611536 = query.getOrDefault("position")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "position", valid_611536
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611537 = header.getOrDefault("X-Amz-Signature")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Signature", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Content-Sha256", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Date")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Date", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Credential")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Credential", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Security-Token")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Security-Token", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Algorithm")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Algorithm", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-SignedHeaders", valid_611543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611544: Call_GetRequestValidators_611531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_611544.validator(path, query, header, formData, body)
  let scheme = call_611544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611544.url(scheme.get, call_611544.host, call_611544.base,
                         call_611544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611544, url, valid)

proc call*(call_611545: Call_GetRequestValidators_611531; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_611546 = newJObject()
  var query_611547 = newJObject()
  add(query_611547, "limit", newJInt(limit))
  add(query_611547, "position", newJString(position))
  add(path_611546, "restapi_id", newJString(restapiId))
  result = call_611545.call(path_611546, query_611547, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_611531(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_611532, base: "/",
    url: url_GetRequestValidators_611533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_611564 = ref object of OpenApiRestCall_610642
proc url_CreateResource_611566(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResource_611565(path: JsonNode; query: JsonNode;
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
  var valid_611567 = path.getOrDefault("restapi_id")
  valid_611567 = validateParameter(valid_611567, JString, required = true,
                                 default = nil)
  if valid_611567 != nil:
    section.add "restapi_id", valid_611567
  var valid_611568 = path.getOrDefault("parent_id")
  valid_611568 = validateParameter(valid_611568, JString, required = true,
                                 default = nil)
  if valid_611568 != nil:
    section.add "parent_id", valid_611568
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_CreateResource_611564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_CreateResource_611564; restapiId: string;
          body: JsonNode; parentId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  var path_611579 = newJObject()
  var body_611580 = newJObject()
  add(path_611579, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611580 = body
  add(path_611579, "parent_id", newJString(parentId))
  result = call_611578.call(path_611579, nil, nil, nil, body_611580)

var createResource* = Call_CreateResource_611564(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_611565, base: "/", url: url_CreateResource_611566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_611596 = ref object of OpenApiRestCall_610642
proc url_CreateRestApi_611598(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRestApi_611597(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_CreateRestApi_611596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_CreateRestApi_611596; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_611609 = newJObject()
  if body != nil:
    body_611609 = body
  result = call_611608.call(nil, nil, nil, nil, body_611609)

var createRestApi* = Call_CreateRestApi_611596(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_611597, base: "/", url: url_CreateRestApi_611598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_611581 = ref object of OpenApiRestCall_610642
proc url_GetRestApis_611583(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestApis_611582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611584 = query.getOrDefault("limit")
  valid_611584 = validateParameter(valid_611584, JInt, required = false, default = nil)
  if valid_611584 != nil:
    section.add "limit", valid_611584
  var valid_611585 = query.getOrDefault("position")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "position", valid_611585
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611586 = header.getOrDefault("X-Amz-Signature")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Signature", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Content-Sha256", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Date")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Date", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Credential")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Credential", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Security-Token")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Security-Token", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Algorithm")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Algorithm", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-SignedHeaders", valid_611592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611593: Call_GetRestApis_611581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_611593.validator(path, query, header, formData, body)
  let scheme = call_611593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611593.url(scheme.get, call_611593.host, call_611593.base,
                         call_611593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611593, url, valid)

proc call*(call_611594: Call_GetRestApis_611581; limit: int = 0; position: string = ""): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_611595 = newJObject()
  add(query_611595, "limit", newJInt(limit))
  add(query_611595, "position", newJString(position))
  result = call_611594.call(nil, query_611595, nil, nil, nil)

var getRestApis* = Call_GetRestApis_611581(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_611582,
                                        base: "/", url: url_GetRestApis_611583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_611626 = ref object of OpenApiRestCall_610642
proc url_CreateStage_611628(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateStage_611627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611629 = path.getOrDefault("restapi_id")
  valid_611629 = validateParameter(valid_611629, JString, required = true,
                                 default = nil)
  if valid_611629 != nil:
    section.add "restapi_id", valid_611629
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611630 = header.getOrDefault("X-Amz-Signature")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Signature", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Content-Sha256", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Date")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Date", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Credential")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Credential", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Security-Token")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Security-Token", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Algorithm")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Algorithm", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-SignedHeaders", valid_611636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611638: Call_CreateStage_611626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_611638.validator(path, query, header, formData, body)
  let scheme = call_611638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611638.url(scheme.get, call_611638.host, call_611638.base,
                         call_611638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611638, url, valid)

proc call*(call_611639: Call_CreateStage_611626; restapiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611640 = newJObject()
  var body_611641 = newJObject()
  add(path_611640, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611641 = body
  result = call_611639.call(path_611640, nil, nil, nil, body_611641)

var createStage* = Call_CreateStage_611626(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_611627,
                                        base: "/", url: url_CreateStage_611628,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_611610 = ref object of OpenApiRestCall_610642
proc url_GetStages_611612(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStages_611611(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611613 = path.getOrDefault("restapi_id")
  valid_611613 = validateParameter(valid_611613, JString, required = true,
                                 default = nil)
  if valid_611613 != nil:
    section.add "restapi_id", valid_611613
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_611614 = query.getOrDefault("deploymentId")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "deploymentId", valid_611614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611615 = header.getOrDefault("X-Amz-Signature")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Signature", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Content-Sha256", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Date")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Date", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Credential")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Credential", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Security-Token")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Security-Token", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Algorithm")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Algorithm", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-SignedHeaders", valid_611621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611622: Call_GetStages_611610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_611622.validator(path, query, header, formData, body)
  let scheme = call_611622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611622.url(scheme.get, call_611622.host, call_611622.base,
                         call_611622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611622, url, valid)

proc call*(call_611623: Call_GetStages_611610; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  var path_611624 = newJObject()
  var query_611625 = newJObject()
  add(path_611624, "restapi_id", newJString(restapiId))
  add(query_611625, "deploymentId", newJString(deploymentId))
  result = call_611623.call(path_611624, query_611625, nil, nil, nil)

var getStages* = Call_GetStages_611610(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_611611,
                                    base: "/", url: url_GetStages_611612,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_611658 = ref object of OpenApiRestCall_610642
proc url_CreateUsagePlan_611660(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUsagePlan_611659(path: JsonNode; query: JsonNode;
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
  var valid_611661 = header.getOrDefault("X-Amz-Signature")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Signature", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Content-Sha256", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Date")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Date", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Credential")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Credential", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Security-Token")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Security-Token", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Algorithm")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Algorithm", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-SignedHeaders", valid_611667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611669: Call_CreateUsagePlan_611658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_611669.validator(path, query, header, formData, body)
  let scheme = call_611669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611669.url(scheme.get, call_611669.host, call_611669.base,
                         call_611669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611669, url, valid)

proc call*(call_611670: Call_CreateUsagePlan_611658; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_611671 = newJObject()
  if body != nil:
    body_611671 = body
  result = call_611670.call(nil, nil, nil, nil, body_611671)

var createUsagePlan* = Call_CreateUsagePlan_611658(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_611659, base: "/",
    url: url_CreateUsagePlan_611660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_611642 = ref object of OpenApiRestCall_610642
proc url_GetUsagePlans_611644(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUsagePlans_611643(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611645 = query.getOrDefault("limit")
  valid_611645 = validateParameter(valid_611645, JInt, required = false, default = nil)
  if valid_611645 != nil:
    section.add "limit", valid_611645
  var valid_611646 = query.getOrDefault("position")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "position", valid_611646
  var valid_611647 = query.getOrDefault("keyId")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "keyId", valid_611647
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_611655: Call_GetUsagePlans_611642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_611655.validator(path, query, header, formData, body)
  let scheme = call_611655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611655.url(scheme.get, call_611655.host, call_611655.base,
                         call_611655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611655, url, valid)

proc call*(call_611656: Call_GetUsagePlans_611642; limit: int = 0;
          position: string = ""; keyId: string = ""): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  var query_611657 = newJObject()
  add(query_611657, "limit", newJInt(limit))
  add(query_611657, "position", newJString(position))
  add(query_611657, "keyId", newJString(keyId))
  result = call_611656.call(nil, query_611657, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_611642(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_611643, base: "/",
    url: url_GetUsagePlans_611644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_611690 = ref object of OpenApiRestCall_610642
proc url_CreateUsagePlanKey_611692(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUsagePlanKey_611691(path: JsonNode; query: JsonNode;
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
  var valid_611693 = path.getOrDefault("usageplanId")
  valid_611693 = validateParameter(valid_611693, JString, required = true,
                                 default = nil)
  if valid_611693 != nil:
    section.add "usageplanId", valid_611693
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611694 = header.getOrDefault("X-Amz-Signature")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Signature", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Content-Sha256", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Date")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Date", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Credential")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Credential", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Security-Token")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Security-Token", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Algorithm")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Algorithm", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-SignedHeaders", valid_611700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611702: Call_CreateUsagePlanKey_611690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_611702.validator(path, query, header, formData, body)
  let scheme = call_611702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611702.url(scheme.get, call_611702.host, call_611702.base,
                         call_611702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611702, url, valid)

proc call*(call_611703: Call_CreateUsagePlanKey_611690; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_611704 = newJObject()
  var body_611705 = newJObject()
  add(path_611704, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_611705 = body
  result = call_611703.call(path_611704, nil, nil, nil, body_611705)

var createUsagePlanKey* = Call_CreateUsagePlanKey_611690(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_611691, base: "/",
    url: url_CreateUsagePlanKey_611692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_611672 = ref object of OpenApiRestCall_610642
proc url_GetUsagePlanKeys_611674(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsagePlanKeys_611673(path: JsonNode; query: JsonNode;
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
  var valid_611675 = path.getOrDefault("usageplanId")
  valid_611675 = validateParameter(valid_611675, JString, required = true,
                                 default = nil)
  if valid_611675 != nil:
    section.add "usageplanId", valid_611675
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_611676 = query.getOrDefault("name")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "name", valid_611676
  var valid_611677 = query.getOrDefault("limit")
  valid_611677 = validateParameter(valid_611677, JInt, required = false, default = nil)
  if valid_611677 != nil:
    section.add "limit", valid_611677
  var valid_611678 = query.getOrDefault("position")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "position", valid_611678
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_611686: Call_GetUsagePlanKeys_611672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_611686.validator(path, query, header, formData, body)
  let scheme = call_611686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611686.url(scheme.get, call_611686.host, call_611686.base,
                         call_611686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611686, url, valid)

proc call*(call_611687: Call_GetUsagePlanKeys_611672; usageplanId: string;
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
  var path_611688 = newJObject()
  var query_611689 = newJObject()
  add(query_611689, "name", newJString(name))
  add(path_611688, "usageplanId", newJString(usageplanId))
  add(query_611689, "limit", newJInt(limit))
  add(query_611689, "position", newJString(position))
  result = call_611687.call(path_611688, query_611689, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_611672(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_611673,
    base: "/", url: url_GetUsagePlanKeys_611674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_611721 = ref object of OpenApiRestCall_610642
proc url_CreateVpcLink_611723(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVpcLink_611722(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611724 = header.getOrDefault("X-Amz-Signature")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Signature", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Content-Sha256", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Date")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Date", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Credential")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Credential", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Security-Token")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Security-Token", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Algorithm")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Algorithm", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-SignedHeaders", valid_611730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611732: Call_CreateVpcLink_611721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_611732.validator(path, query, header, formData, body)
  let scheme = call_611732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611732.url(scheme.get, call_611732.host, call_611732.base,
                         call_611732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611732, url, valid)

proc call*(call_611733: Call_CreateVpcLink_611721; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_611734 = newJObject()
  if body != nil:
    body_611734 = body
  result = call_611733.call(nil, nil, nil, nil, body_611734)

var createVpcLink* = Call_CreateVpcLink_611721(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_611722, base: "/", url: url_CreateVpcLink_611723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_611706 = ref object of OpenApiRestCall_610642
proc url_GetVpcLinks_611708(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVpcLinks_611707(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611709 = query.getOrDefault("limit")
  valid_611709 = validateParameter(valid_611709, JInt, required = false, default = nil)
  if valid_611709 != nil:
    section.add "limit", valid_611709
  var valid_611710 = query.getOrDefault("position")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "position", valid_611710
  result.add "query", section
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

proc call*(call_611718: Call_GetVpcLinks_611706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_611718.validator(path, query, header, formData, body)
  let scheme = call_611718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611718.url(scheme.get, call_611718.host, call_611718.base,
                         call_611718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611718, url, valid)

proc call*(call_611719: Call_GetVpcLinks_611706; limit: int = 0; position: string = ""): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_611720 = newJObject()
  add(query_611720, "limit", newJInt(limit))
  add(query_611720, "position", newJString(position))
  result = call_611719.call(nil, query_611720, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_611706(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_611707,
                                        base: "/", url: url_GetVpcLinks_611708,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_611735 = ref object of OpenApiRestCall_610642
proc url_GetApiKey_611737(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiKey_611736(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611738 = path.getOrDefault("api_Key")
  valid_611738 = validateParameter(valid_611738, JString, required = true,
                                 default = nil)
  if valid_611738 != nil:
    section.add "api_Key", valid_611738
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_611739 = query.getOrDefault("includeValue")
  valid_611739 = validateParameter(valid_611739, JBool, required = false, default = nil)
  if valid_611739 != nil:
    section.add "includeValue", valid_611739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611740 = header.getOrDefault("X-Amz-Signature")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Signature", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Content-Sha256", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Date")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Date", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Credential")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Credential", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Security-Token")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Security-Token", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Algorithm")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Algorithm", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-SignedHeaders", valid_611746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611747: Call_GetApiKey_611735; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_611747.validator(path, query, header, formData, body)
  let scheme = call_611747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611747.url(scheme.get, call_611747.host, call_611747.base,
                         call_611747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611747, url, valid)

proc call*(call_611748: Call_GetApiKey_611735; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_611749 = newJObject()
  var query_611750 = newJObject()
  add(query_611750, "includeValue", newJBool(includeValue))
  add(path_611749, "api_Key", newJString(apiKey))
  result = call_611748.call(path_611749, query_611750, nil, nil, nil)

var getApiKey* = Call_GetApiKey_611735(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_611736,
                                    base: "/", url: url_GetApiKey_611737,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_611765 = ref object of OpenApiRestCall_610642
proc url_UpdateApiKey_611767(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiKey_611766(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611768 = path.getOrDefault("api_Key")
  valid_611768 = validateParameter(valid_611768, JString, required = true,
                                 default = nil)
  if valid_611768 != nil:
    section.add "api_Key", valid_611768
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611769 = header.getOrDefault("X-Amz-Signature")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Signature", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Content-Sha256", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Date")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Date", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Credential")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Credential", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Security-Token")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Security-Token", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Algorithm")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Algorithm", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-SignedHeaders", valid_611775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611777: Call_UpdateApiKey_611765; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_611777.validator(path, query, header, formData, body)
  let scheme = call_611777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611777.url(scheme.get, call_611777.host, call_611777.base,
                         call_611777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611777, url, valid)

proc call*(call_611778: Call_UpdateApiKey_611765; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_611779 = newJObject()
  var body_611780 = newJObject()
  add(path_611779, "api_Key", newJString(apiKey))
  if body != nil:
    body_611780 = body
  result = call_611778.call(path_611779, nil, nil, nil, body_611780)

var updateApiKey* = Call_UpdateApiKey_611765(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_611766, base: "/",
    url: url_UpdateApiKey_611767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_611751 = ref object of OpenApiRestCall_610642
proc url_DeleteApiKey_611753(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiKey_611752(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611754 = path.getOrDefault("api_Key")
  valid_611754 = validateParameter(valid_611754, JString, required = true,
                                 default = nil)
  if valid_611754 != nil:
    section.add "api_Key", valid_611754
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611755 = header.getOrDefault("X-Amz-Signature")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Signature", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Content-Sha256", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Date")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Date", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Credential")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Credential", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Security-Token")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Security-Token", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Algorithm")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Algorithm", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-SignedHeaders", valid_611761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611762: Call_DeleteApiKey_611751; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_611762.validator(path, query, header, formData, body)
  let scheme = call_611762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611762.url(scheme.get, call_611762.host, call_611762.base,
                         call_611762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611762, url, valid)

proc call*(call_611763: Call_DeleteApiKey_611751; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_611764 = newJObject()
  add(path_611764, "api_Key", newJString(apiKey))
  result = call_611763.call(path_611764, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_611751(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_611752, base: "/",
    url: url_DeleteApiKey_611753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_611796 = ref object of OpenApiRestCall_610642
proc url_TestInvokeAuthorizer_611798(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TestInvokeAuthorizer_611797(path: JsonNode; query: JsonNode;
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
  var valid_611799 = path.getOrDefault("restapi_id")
  valid_611799 = validateParameter(valid_611799, JString, required = true,
                                 default = nil)
  if valid_611799 != nil:
    section.add "restapi_id", valid_611799
  var valid_611800 = path.getOrDefault("authorizer_id")
  valid_611800 = validateParameter(valid_611800, JString, required = true,
                                 default = nil)
  if valid_611800 != nil:
    section.add "authorizer_id", valid_611800
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611801 = header.getOrDefault("X-Amz-Signature")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Signature", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Content-Sha256", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Date")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Date", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Credential")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Credential", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Security-Token")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Security-Token", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Algorithm")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Algorithm", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-SignedHeaders", valid_611807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611809: Call_TestInvokeAuthorizer_611796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_611809.validator(path, query, header, formData, body)
  let scheme = call_611809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611809.url(scheme.get, call_611809.host, call_611809.base,
                         call_611809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611809, url, valid)

proc call*(call_611810: Call_TestInvokeAuthorizer_611796; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  var path_611811 = newJObject()
  var body_611812 = newJObject()
  add(path_611811, "restapi_id", newJString(restapiId))
  add(path_611811, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_611812 = body
  result = call_611810.call(path_611811, nil, nil, nil, body_611812)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_611796(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_611797, base: "/",
    url: url_TestInvokeAuthorizer_611798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_611781 = ref object of OpenApiRestCall_610642
proc url_GetAuthorizer_611783(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizer_611782(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611784 = path.getOrDefault("restapi_id")
  valid_611784 = validateParameter(valid_611784, JString, required = true,
                                 default = nil)
  if valid_611784 != nil:
    section.add "restapi_id", valid_611784
  var valid_611785 = path.getOrDefault("authorizer_id")
  valid_611785 = validateParameter(valid_611785, JString, required = true,
                                 default = nil)
  if valid_611785 != nil:
    section.add "authorizer_id", valid_611785
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611786 = header.getOrDefault("X-Amz-Signature")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Signature", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Content-Sha256", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Date")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Date", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Credential")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Credential", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Security-Token")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Security-Token", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Algorithm")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Algorithm", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-SignedHeaders", valid_611792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611793: Call_GetAuthorizer_611781; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_611793.validator(path, query, header, formData, body)
  let scheme = call_611793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611793.url(scheme.get, call_611793.host, call_611793.base,
                         call_611793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611793, url, valid)

proc call*(call_611794: Call_GetAuthorizer_611781; restapiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_611795 = newJObject()
  add(path_611795, "restapi_id", newJString(restapiId))
  add(path_611795, "authorizer_id", newJString(authorizerId))
  result = call_611794.call(path_611795, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_611781(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_611782, base: "/", url: url_GetAuthorizer_611783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_611828 = ref object of OpenApiRestCall_610642
proc url_UpdateAuthorizer_611830(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAuthorizer_611829(path: JsonNode; query: JsonNode;
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
  var valid_611831 = path.getOrDefault("restapi_id")
  valid_611831 = validateParameter(valid_611831, JString, required = true,
                                 default = nil)
  if valid_611831 != nil:
    section.add "restapi_id", valid_611831
  var valid_611832 = path.getOrDefault("authorizer_id")
  valid_611832 = validateParameter(valid_611832, JString, required = true,
                                 default = nil)
  if valid_611832 != nil:
    section.add "authorizer_id", valid_611832
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611833 = header.getOrDefault("X-Amz-Signature")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Signature", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Content-Sha256", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Date")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Date", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Credential")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Credential", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-Security-Token")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Security-Token", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-Algorithm")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-Algorithm", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-SignedHeaders", valid_611839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611841: Call_UpdateAuthorizer_611828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_611841.validator(path, query, header, formData, body)
  let scheme = call_611841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611841.url(scheme.get, call_611841.host, call_611841.base,
                         call_611841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611841, url, valid)

proc call*(call_611842: Call_UpdateAuthorizer_611828; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  var path_611843 = newJObject()
  var body_611844 = newJObject()
  add(path_611843, "restapi_id", newJString(restapiId))
  add(path_611843, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_611844 = body
  result = call_611842.call(path_611843, nil, nil, nil, body_611844)

var updateAuthorizer* = Call_UpdateAuthorizer_611828(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_611829, base: "/",
    url: url_UpdateAuthorizer_611830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_611813 = ref object of OpenApiRestCall_610642
proc url_DeleteAuthorizer_611815(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAuthorizer_611814(path: JsonNode; query: JsonNode;
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
  var valid_611816 = path.getOrDefault("restapi_id")
  valid_611816 = validateParameter(valid_611816, JString, required = true,
                                 default = nil)
  if valid_611816 != nil:
    section.add "restapi_id", valid_611816
  var valid_611817 = path.getOrDefault("authorizer_id")
  valid_611817 = validateParameter(valid_611817, JString, required = true,
                                 default = nil)
  if valid_611817 != nil:
    section.add "authorizer_id", valid_611817
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611818 = header.getOrDefault("X-Amz-Signature")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Signature", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Content-Sha256", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-Date")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Date", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Credential")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Credential", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-Security-Token")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-Security-Token", valid_611822
  var valid_611823 = header.getOrDefault("X-Amz-Algorithm")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Algorithm", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-SignedHeaders", valid_611824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611825: Call_DeleteAuthorizer_611813; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_611825.validator(path, query, header, formData, body)
  let scheme = call_611825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611825.url(scheme.get, call_611825.host, call_611825.base,
                         call_611825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611825, url, valid)

proc call*(call_611826: Call_DeleteAuthorizer_611813; restapiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_611827 = newJObject()
  add(path_611827, "restapi_id", newJString(restapiId))
  add(path_611827, "authorizer_id", newJString(authorizerId))
  result = call_611826.call(path_611827, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_611813(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_611814, base: "/",
    url: url_DeleteAuthorizer_611815, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_611845 = ref object of OpenApiRestCall_610642
proc url_GetBasePathMapping_611847(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBasePathMapping_611846(path: JsonNode; query: JsonNode;
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
  var valid_611848 = path.getOrDefault("base_path")
  valid_611848 = validateParameter(valid_611848, JString, required = true,
                                 default = nil)
  if valid_611848 != nil:
    section.add "base_path", valid_611848
  var valid_611849 = path.getOrDefault("domain_name")
  valid_611849 = validateParameter(valid_611849, JString, required = true,
                                 default = nil)
  if valid_611849 != nil:
    section.add "domain_name", valid_611849
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_611857: Call_GetBasePathMapping_611845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_611857.validator(path, query, header, formData, body)
  let scheme = call_611857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611857.url(scheme.get, call_611857.host, call_611857.base,
                         call_611857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611857, url, valid)

proc call*(call_611858: Call_GetBasePathMapping_611845; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_611859 = newJObject()
  add(path_611859, "base_path", newJString(basePath))
  add(path_611859, "domain_name", newJString(domainName))
  result = call_611858.call(path_611859, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_611845(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_611846, base: "/",
    url: url_GetBasePathMapping_611847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_611875 = ref object of OpenApiRestCall_610642
proc url_UpdateBasePathMapping_611877(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBasePathMapping_611876(path: JsonNode; query: JsonNode;
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
  var valid_611878 = path.getOrDefault("base_path")
  valid_611878 = validateParameter(valid_611878, JString, required = true,
                                 default = nil)
  if valid_611878 != nil:
    section.add "base_path", valid_611878
  var valid_611879 = path.getOrDefault("domain_name")
  valid_611879 = validateParameter(valid_611879, JString, required = true,
                                 default = nil)
  if valid_611879 != nil:
    section.add "domain_name", valid_611879
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611880 = header.getOrDefault("X-Amz-Signature")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Signature", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Content-Sha256", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Date")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Date", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Credential")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Credential", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Security-Token")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Security-Token", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Algorithm")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Algorithm", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-SignedHeaders", valid_611886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611888: Call_UpdateBasePathMapping_611875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_611888.validator(path, query, header, formData, body)
  let scheme = call_611888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611888.url(scheme.get, call_611888.host, call_611888.base,
                         call_611888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611888, url, valid)

proc call*(call_611889: Call_UpdateBasePathMapping_611875; basePath: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  var path_611890 = newJObject()
  var body_611891 = newJObject()
  add(path_611890, "base_path", newJString(basePath))
  if body != nil:
    body_611891 = body
  add(path_611890, "domain_name", newJString(domainName))
  result = call_611889.call(path_611890, nil, nil, nil, body_611891)

var updateBasePathMapping* = Call_UpdateBasePathMapping_611875(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_611876, base: "/",
    url: url_UpdateBasePathMapping_611877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_611860 = ref object of OpenApiRestCall_610642
proc url_DeleteBasePathMapping_611862(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBasePathMapping_611861(path: JsonNode; query: JsonNode;
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
  var valid_611863 = path.getOrDefault("base_path")
  valid_611863 = validateParameter(valid_611863, JString, required = true,
                                 default = nil)
  if valid_611863 != nil:
    section.add "base_path", valid_611863
  var valid_611864 = path.getOrDefault("domain_name")
  valid_611864 = validateParameter(valid_611864, JString, required = true,
                                 default = nil)
  if valid_611864 != nil:
    section.add "domain_name", valid_611864
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611865 = header.getOrDefault("X-Amz-Signature")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Signature", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Content-Sha256", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Date")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Date", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Credential")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Credential", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Security-Token")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Security-Token", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Algorithm")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Algorithm", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-SignedHeaders", valid_611871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611872: Call_DeleteBasePathMapping_611860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_611872.validator(path, query, header, formData, body)
  let scheme = call_611872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611872.url(scheme.get, call_611872.host, call_611872.base,
                         call_611872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611872, url, valid)

proc call*(call_611873: Call_DeleteBasePathMapping_611860; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_611874 = newJObject()
  add(path_611874, "base_path", newJString(basePath))
  add(path_611874, "domain_name", newJString(domainName))
  result = call_611873.call(path_611874, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_611860(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_611861, base: "/",
    url: url_DeleteBasePathMapping_611862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_611892 = ref object of OpenApiRestCall_610642
proc url_GetClientCertificate_611894(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetClientCertificate_611893(path: JsonNode; query: JsonNode;
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
  var valid_611895 = path.getOrDefault("clientcertificate_id")
  valid_611895 = validateParameter(valid_611895, JString, required = true,
                                 default = nil)
  if valid_611895 != nil:
    section.add "clientcertificate_id", valid_611895
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611896 = header.getOrDefault("X-Amz-Signature")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Signature", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Content-Sha256", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Date")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Date", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Credential")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Credential", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Security-Token")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Security-Token", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Algorithm")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Algorithm", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-SignedHeaders", valid_611902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611903: Call_GetClientCertificate_611892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_611903.validator(path, query, header, formData, body)
  let scheme = call_611903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611903.url(scheme.get, call_611903.host, call_611903.base,
                         call_611903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611903, url, valid)

proc call*(call_611904: Call_GetClientCertificate_611892;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_611905 = newJObject()
  add(path_611905, "clientcertificate_id", newJString(clientcertificateId))
  result = call_611904.call(path_611905, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_611892(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_611893, base: "/",
    url: url_GetClientCertificate_611894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_611920 = ref object of OpenApiRestCall_610642
proc url_UpdateClientCertificate_611922(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClientCertificate_611921(path: JsonNode; query: JsonNode;
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
  var valid_611923 = path.getOrDefault("clientcertificate_id")
  valid_611923 = validateParameter(valid_611923, JString, required = true,
                                 default = nil)
  if valid_611923 != nil:
    section.add "clientcertificate_id", valid_611923
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611924 = header.getOrDefault("X-Amz-Signature")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Signature", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Content-Sha256", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Date")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Date", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Credential")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Credential", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Security-Token")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Security-Token", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Algorithm")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Algorithm", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-SignedHeaders", valid_611930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611932: Call_UpdateClientCertificate_611920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_611932.validator(path, query, header, formData, body)
  let scheme = call_611932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611932.url(scheme.get, call_611932.host, call_611932.base,
                         call_611932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611932, url, valid)

proc call*(call_611933: Call_UpdateClientCertificate_611920;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_611934 = newJObject()
  var body_611935 = newJObject()
  add(path_611934, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_611935 = body
  result = call_611933.call(path_611934, nil, nil, nil, body_611935)

var updateClientCertificate* = Call_UpdateClientCertificate_611920(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_611921, base: "/",
    url: url_UpdateClientCertificate_611922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_611906 = ref object of OpenApiRestCall_610642
proc url_DeleteClientCertificate_611908(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteClientCertificate_611907(path: JsonNode; query: JsonNode;
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
  var valid_611909 = path.getOrDefault("clientcertificate_id")
  valid_611909 = validateParameter(valid_611909, JString, required = true,
                                 default = nil)
  if valid_611909 != nil:
    section.add "clientcertificate_id", valid_611909
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_611917: Call_DeleteClientCertificate_611906; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_611917.validator(path, query, header, formData, body)
  let scheme = call_611917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611917.url(scheme.get, call_611917.host, call_611917.base,
                         call_611917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611917, url, valid)

proc call*(call_611918: Call_DeleteClientCertificate_611906;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_611919 = newJObject()
  add(path_611919, "clientcertificate_id", newJString(clientcertificateId))
  result = call_611918.call(path_611919, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_611906(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_611907, base: "/",
    url: url_DeleteClientCertificate_611908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_611936 = ref object of OpenApiRestCall_610642
proc url_GetDeployment_611938(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_611937(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611939 = path.getOrDefault("deployment_id")
  valid_611939 = validateParameter(valid_611939, JString, required = true,
                                 default = nil)
  if valid_611939 != nil:
    section.add "deployment_id", valid_611939
  var valid_611940 = path.getOrDefault("restapi_id")
  valid_611940 = validateParameter(valid_611940, JString, required = true,
                                 default = nil)
  if valid_611940 != nil:
    section.add "restapi_id", valid_611940
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_611941 = query.getOrDefault("embed")
  valid_611941 = validateParameter(valid_611941, JArray, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "embed", valid_611941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611942 = header.getOrDefault("X-Amz-Signature")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-Signature", valid_611942
  var valid_611943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Content-Sha256", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Date")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Date", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Credential")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Credential", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Security-Token")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Security-Token", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Algorithm")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Algorithm", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-SignedHeaders", valid_611948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611949: Call_GetDeployment_611936; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_611949.validator(path, query, header, formData, body)
  let scheme = call_611949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611949.url(scheme.get, call_611949.host, call_611949.base,
                         call_611949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611949, url, valid)

proc call*(call_611950: Call_GetDeployment_611936; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  var path_611951 = newJObject()
  var query_611952 = newJObject()
  add(path_611951, "deployment_id", newJString(deploymentId))
  add(path_611951, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_611952.add "embed", embed
  result = call_611950.call(path_611951, query_611952, nil, nil, nil)

var getDeployment* = Call_GetDeployment_611936(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_611937, base: "/", url: url_GetDeployment_611938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_611968 = ref object of OpenApiRestCall_610642
proc url_UpdateDeployment_611970(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeployment_611969(path: JsonNode; query: JsonNode;
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
  var valid_611971 = path.getOrDefault("deployment_id")
  valid_611971 = validateParameter(valid_611971, JString, required = true,
                                 default = nil)
  if valid_611971 != nil:
    section.add "deployment_id", valid_611971
  var valid_611972 = path.getOrDefault("restapi_id")
  valid_611972 = validateParameter(valid_611972, JString, required = true,
                                 default = nil)
  if valid_611972 != nil:
    section.add "restapi_id", valid_611972
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611973 = header.getOrDefault("X-Amz-Signature")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Signature", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Content-Sha256", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Date")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Date", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Credential")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Credential", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Security-Token")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Security-Token", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Algorithm")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Algorithm", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-SignedHeaders", valid_611979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611981: Call_UpdateDeployment_611968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_611981.validator(path, query, header, formData, body)
  let scheme = call_611981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611981.url(scheme.get, call_611981.host, call_611981.base,
                         call_611981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611981, url, valid)

proc call*(call_611982: Call_UpdateDeployment_611968; deploymentId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_611983 = newJObject()
  var body_611984 = newJObject()
  add(path_611983, "deployment_id", newJString(deploymentId))
  add(path_611983, "restapi_id", newJString(restapiId))
  if body != nil:
    body_611984 = body
  result = call_611982.call(path_611983, nil, nil, nil, body_611984)

var updateDeployment* = Call_UpdateDeployment_611968(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_611969, base: "/",
    url: url_UpdateDeployment_611970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_611953 = ref object of OpenApiRestCall_610642
proc url_DeleteDeployment_611955(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeployment_611954(path: JsonNode; query: JsonNode;
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
  var valid_611956 = path.getOrDefault("deployment_id")
  valid_611956 = validateParameter(valid_611956, JString, required = true,
                                 default = nil)
  if valid_611956 != nil:
    section.add "deployment_id", valid_611956
  var valid_611957 = path.getOrDefault("restapi_id")
  valid_611957 = validateParameter(valid_611957, JString, required = true,
                                 default = nil)
  if valid_611957 != nil:
    section.add "restapi_id", valid_611957
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611958 = header.getOrDefault("X-Amz-Signature")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Signature", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Content-Sha256", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Date")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Date", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Credential")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Credential", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Security-Token")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Security-Token", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Algorithm")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Algorithm", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-SignedHeaders", valid_611964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611965: Call_DeleteDeployment_611953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_611965.validator(path, query, header, formData, body)
  let scheme = call_611965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611965.url(scheme.get, call_611965.host, call_611965.base,
                         call_611965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611965, url, valid)

proc call*(call_611966: Call_DeleteDeployment_611953; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_611967 = newJObject()
  add(path_611967, "deployment_id", newJString(deploymentId))
  add(path_611967, "restapi_id", newJString(restapiId))
  result = call_611966.call(path_611967, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_611953(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_611954, base: "/",
    url: url_DeleteDeployment_611955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_611985 = ref object of OpenApiRestCall_610642
proc url_GetDocumentationPart_611987(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationPart_611986(path: JsonNode; query: JsonNode;
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
  var valid_611988 = path.getOrDefault("part_id")
  valid_611988 = validateParameter(valid_611988, JString, required = true,
                                 default = nil)
  if valid_611988 != nil:
    section.add "part_id", valid_611988
  var valid_611989 = path.getOrDefault("restapi_id")
  valid_611989 = validateParameter(valid_611989, JString, required = true,
                                 default = nil)
  if valid_611989 != nil:
    section.add "restapi_id", valid_611989
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611990 = header.getOrDefault("X-Amz-Signature")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Signature", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Content-Sha256", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Date")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Date", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Credential")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Credential", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Security-Token")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Security-Token", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-Algorithm")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Algorithm", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-SignedHeaders", valid_611996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_GetDocumentationPart_611985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_GetDocumentationPart_611985; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_611999 = newJObject()
  add(path_611999, "part_id", newJString(partId))
  add(path_611999, "restapi_id", newJString(restapiId))
  result = call_611998.call(path_611999, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_611985(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_611986, base: "/",
    url: url_GetDocumentationPart_611987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_612015 = ref object of OpenApiRestCall_610642
proc url_UpdateDocumentationPart_612017(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocumentationPart_612016(path: JsonNode; query: JsonNode;
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
  var valid_612018 = path.getOrDefault("part_id")
  valid_612018 = validateParameter(valid_612018, JString, required = true,
                                 default = nil)
  if valid_612018 != nil:
    section.add "part_id", valid_612018
  var valid_612019 = path.getOrDefault("restapi_id")
  valid_612019 = validateParameter(valid_612019, JString, required = true,
                                 default = nil)
  if valid_612019 != nil:
    section.add "restapi_id", valid_612019
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612020 = header.getOrDefault("X-Amz-Signature")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-Signature", valid_612020
  var valid_612021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "X-Amz-Content-Sha256", valid_612021
  var valid_612022 = header.getOrDefault("X-Amz-Date")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Date", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Credential")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Credential", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Security-Token")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Security-Token", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Algorithm")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Algorithm", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-SignedHeaders", valid_612026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612028: Call_UpdateDocumentationPart_612015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612028.validator(path, query, header, formData, body)
  let scheme = call_612028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612028.url(scheme.get, call_612028.host, call_612028.base,
                         call_612028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612028, url, valid)

proc call*(call_612029: Call_UpdateDocumentationPart_612015; partId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_612030 = newJObject()
  var body_612031 = newJObject()
  add(path_612030, "part_id", newJString(partId))
  add(path_612030, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612031 = body
  result = call_612029.call(path_612030, nil, nil, nil, body_612031)

var updateDocumentationPart* = Call_UpdateDocumentationPart_612015(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_612016, base: "/",
    url: url_UpdateDocumentationPart_612017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_612000 = ref object of OpenApiRestCall_610642
proc url_DeleteDocumentationPart_612002(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDocumentationPart_612001(path: JsonNode; query: JsonNode;
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
  var valid_612003 = path.getOrDefault("part_id")
  valid_612003 = validateParameter(valid_612003, JString, required = true,
                                 default = nil)
  if valid_612003 != nil:
    section.add "part_id", valid_612003
  var valid_612004 = path.getOrDefault("restapi_id")
  valid_612004 = validateParameter(valid_612004, JString, required = true,
                                 default = nil)
  if valid_612004 != nil:
    section.add "restapi_id", valid_612004
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612005 = header.getOrDefault("X-Amz-Signature")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Signature", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Content-Sha256", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Date")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Date", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Credential")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Credential", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Security-Token")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Security-Token", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Algorithm")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Algorithm", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-SignedHeaders", valid_612011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612012: Call_DeleteDocumentationPart_612000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612012.validator(path, query, header, formData, body)
  let scheme = call_612012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612012.url(scheme.get, call_612012.host, call_612012.base,
                         call_612012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612012, url, valid)

proc call*(call_612013: Call_DeleteDocumentationPart_612000; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_612014 = newJObject()
  add(path_612014, "part_id", newJString(partId))
  add(path_612014, "restapi_id", newJString(restapiId))
  result = call_612013.call(path_612014, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_612000(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_612001, base: "/",
    url: url_DeleteDocumentationPart_612002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_612032 = ref object of OpenApiRestCall_610642
proc url_GetDocumentationVersion_612034(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentationVersion_612033(path: JsonNode; query: JsonNode;
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
  var valid_612035 = path.getOrDefault("doc_version")
  valid_612035 = validateParameter(valid_612035, JString, required = true,
                                 default = nil)
  if valid_612035 != nil:
    section.add "doc_version", valid_612035
  var valid_612036 = path.getOrDefault("restapi_id")
  valid_612036 = validateParameter(valid_612036, JString, required = true,
                                 default = nil)
  if valid_612036 != nil:
    section.add "restapi_id", valid_612036
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612037 = header.getOrDefault("X-Amz-Signature")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "X-Amz-Signature", valid_612037
  var valid_612038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-Content-Sha256", valid_612038
  var valid_612039 = header.getOrDefault("X-Amz-Date")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Date", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-Credential")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-Credential", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Security-Token")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Security-Token", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Algorithm")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Algorithm", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-SignedHeaders", valid_612043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612044: Call_GetDocumentationVersion_612032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612044.validator(path, query, header, formData, body)
  let scheme = call_612044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612044.url(scheme.get, call_612044.host, call_612044.base,
                         call_612044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612044, url, valid)

proc call*(call_612045: Call_GetDocumentationVersion_612032; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_612046 = newJObject()
  add(path_612046, "doc_version", newJString(docVersion))
  add(path_612046, "restapi_id", newJString(restapiId))
  result = call_612045.call(path_612046, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_612032(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_612033, base: "/",
    url: url_GetDocumentationVersion_612034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_612062 = ref object of OpenApiRestCall_610642
proc url_UpdateDocumentationVersion_612064(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocumentationVersion_612063(path: JsonNode; query: JsonNode;
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
  var valid_612065 = path.getOrDefault("doc_version")
  valid_612065 = validateParameter(valid_612065, JString, required = true,
                                 default = nil)
  if valid_612065 != nil:
    section.add "doc_version", valid_612065
  var valid_612066 = path.getOrDefault("restapi_id")
  valid_612066 = validateParameter(valid_612066, JString, required = true,
                                 default = nil)
  if valid_612066 != nil:
    section.add "restapi_id", valid_612066
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612067 = header.getOrDefault("X-Amz-Signature")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Signature", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Content-Sha256", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Date")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Date", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-Credential")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-Credential", valid_612070
  var valid_612071 = header.getOrDefault("X-Amz-Security-Token")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-Security-Token", valid_612071
  var valid_612072 = header.getOrDefault("X-Amz-Algorithm")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "X-Amz-Algorithm", valid_612072
  var valid_612073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "X-Amz-SignedHeaders", valid_612073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612075: Call_UpdateDocumentationVersion_612062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612075.validator(path, query, header, formData, body)
  let scheme = call_612075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612075.url(scheme.get, call_612075.host, call_612075.base,
                         call_612075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612075, url, valid)

proc call*(call_612076: Call_UpdateDocumentationVersion_612062; docVersion: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  ##   body: JObject (required)
  var path_612077 = newJObject()
  var body_612078 = newJObject()
  add(path_612077, "doc_version", newJString(docVersion))
  add(path_612077, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612078 = body
  result = call_612076.call(path_612077, nil, nil, nil, body_612078)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_612062(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_612063, base: "/",
    url: url_UpdateDocumentationVersion_612064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_612047 = ref object of OpenApiRestCall_610642
proc url_DeleteDocumentationVersion_612049(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDocumentationVersion_612048(path: JsonNode; query: JsonNode;
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
  var valid_612050 = path.getOrDefault("doc_version")
  valid_612050 = validateParameter(valid_612050, JString, required = true,
                                 default = nil)
  if valid_612050 != nil:
    section.add "doc_version", valid_612050
  var valid_612051 = path.getOrDefault("restapi_id")
  valid_612051 = validateParameter(valid_612051, JString, required = true,
                                 default = nil)
  if valid_612051 != nil:
    section.add "restapi_id", valid_612051
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612052 = header.getOrDefault("X-Amz-Signature")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Signature", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Content-Sha256", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Date")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Date", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-Credential")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-Credential", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-Security-Token")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Security-Token", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Algorithm")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Algorithm", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-SignedHeaders", valid_612058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612059: Call_DeleteDocumentationVersion_612047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612059.validator(path, query, header, formData, body)
  let scheme = call_612059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612059.url(scheme.get, call_612059.host, call_612059.base,
                         call_612059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612059, url, valid)

proc call*(call_612060: Call_DeleteDocumentationVersion_612047; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_612061 = newJObject()
  add(path_612061, "doc_version", newJString(docVersion))
  add(path_612061, "restapi_id", newJString(restapiId))
  result = call_612060.call(path_612061, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_612047(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_612048, base: "/",
    url: url_DeleteDocumentationVersion_612049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_612079 = ref object of OpenApiRestCall_610642
proc url_GetDomainName_612081(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainName_612080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612082 = path.getOrDefault("domain_name")
  valid_612082 = validateParameter(valid_612082, JString, required = true,
                                 default = nil)
  if valid_612082 != nil:
    section.add "domain_name", valid_612082
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612083 = header.getOrDefault("X-Amz-Signature")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "X-Amz-Signature", valid_612083
  var valid_612084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "X-Amz-Content-Sha256", valid_612084
  var valid_612085 = header.getOrDefault("X-Amz-Date")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "X-Amz-Date", valid_612085
  var valid_612086 = header.getOrDefault("X-Amz-Credential")
  valid_612086 = validateParameter(valid_612086, JString, required = false,
                                 default = nil)
  if valid_612086 != nil:
    section.add "X-Amz-Credential", valid_612086
  var valid_612087 = header.getOrDefault("X-Amz-Security-Token")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "X-Amz-Security-Token", valid_612087
  var valid_612088 = header.getOrDefault("X-Amz-Algorithm")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Algorithm", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-SignedHeaders", valid_612089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612090: Call_GetDomainName_612079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_612090.validator(path, query, header, formData, body)
  let scheme = call_612090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612090.url(scheme.get, call_612090.host, call_612090.base,
                         call_612090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612090, url, valid)

proc call*(call_612091: Call_GetDomainName_612079; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_612092 = newJObject()
  add(path_612092, "domain_name", newJString(domainName))
  result = call_612091.call(path_612092, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_612079(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_612080,
    base: "/", url: url_GetDomainName_612081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_612107 = ref object of OpenApiRestCall_610642
proc url_UpdateDomainName_612109(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainName_612108(path: JsonNode; query: JsonNode;
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
  var valid_612110 = path.getOrDefault("domain_name")
  valid_612110 = validateParameter(valid_612110, JString, required = true,
                                 default = nil)
  if valid_612110 != nil:
    section.add "domain_name", valid_612110
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612111 = header.getOrDefault("X-Amz-Signature")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "X-Amz-Signature", valid_612111
  var valid_612112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Content-Sha256", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Date")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Date", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Credential")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Credential", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Security-Token")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Security-Token", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Algorithm")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Algorithm", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-SignedHeaders", valid_612117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612119: Call_UpdateDomainName_612107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_612119.validator(path, query, header, formData, body)
  let scheme = call_612119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612119.url(scheme.get, call_612119.host, call_612119.base,
                         call_612119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612119, url, valid)

proc call*(call_612120: Call_UpdateDomainName_612107; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  var path_612121 = newJObject()
  var body_612122 = newJObject()
  if body != nil:
    body_612122 = body
  add(path_612121, "domain_name", newJString(domainName))
  result = call_612120.call(path_612121, nil, nil, nil, body_612122)

var updateDomainName* = Call_UpdateDomainName_612107(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_612108,
    base: "/", url: url_UpdateDomainName_612109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_612093 = ref object of OpenApiRestCall_610642
proc url_DeleteDomainName_612095(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainName_612094(path: JsonNode; query: JsonNode;
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
  var valid_612096 = path.getOrDefault("domain_name")
  valid_612096 = validateParameter(valid_612096, JString, required = true,
                                 default = nil)
  if valid_612096 != nil:
    section.add "domain_name", valid_612096
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612097 = header.getOrDefault("X-Amz-Signature")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Signature", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Content-Sha256", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-Date")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-Date", valid_612099
  var valid_612100 = header.getOrDefault("X-Amz-Credential")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-Credential", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-Security-Token")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Security-Token", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Algorithm")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Algorithm", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-SignedHeaders", valid_612103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612104: Call_DeleteDomainName_612093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_612104.validator(path, query, header, formData, body)
  let scheme = call_612104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612104.url(scheme.get, call_612104.host, call_612104.base,
                         call_612104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612104, url, valid)

proc call*(call_612105: Call_DeleteDomainName_612093; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_612106 = newJObject()
  add(path_612106, "domain_name", newJString(domainName))
  result = call_612105.call(path_612106, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_612093(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_612094,
    base: "/", url: url_DeleteDomainName_612095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_612138 = ref object of OpenApiRestCall_610642
proc url_PutGatewayResponse_612140(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutGatewayResponse_612139(path: JsonNode; query: JsonNode;
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
  var valid_612141 = path.getOrDefault("response_type")
  valid_612141 = validateParameter(valid_612141, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_612141 != nil:
    section.add "response_type", valid_612141
  var valid_612142 = path.getOrDefault("restapi_id")
  valid_612142 = validateParameter(valid_612142, JString, required = true,
                                 default = nil)
  if valid_612142 != nil:
    section.add "restapi_id", valid_612142
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612143 = header.getOrDefault("X-Amz-Signature")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Signature", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Content-Sha256", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-Date")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Date", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Credential")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Credential", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Security-Token")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Security-Token", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Algorithm")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Algorithm", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-SignedHeaders", valid_612149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612151: Call_PutGatewayResponse_612138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_612151.validator(path, query, header, formData, body)
  let scheme = call_612151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612151.url(scheme.get, call_612151.host, call_612151.base,
                         call_612151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612151, url, valid)

proc call*(call_612152: Call_PutGatewayResponse_612138; restapiId: string;
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
  var path_612153 = newJObject()
  var body_612154 = newJObject()
  add(path_612153, "response_type", newJString(responseType))
  add(path_612153, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612154 = body
  result = call_612152.call(path_612153, nil, nil, nil, body_612154)

var putGatewayResponse* = Call_PutGatewayResponse_612138(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_612139, base: "/",
    url: url_PutGatewayResponse_612140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_612123 = ref object of OpenApiRestCall_610642
proc url_GetGatewayResponse_612125(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGatewayResponse_612124(path: JsonNode; query: JsonNode;
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
  var valid_612126 = path.getOrDefault("response_type")
  valid_612126 = validateParameter(valid_612126, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_612126 != nil:
    section.add "response_type", valid_612126
  var valid_612127 = path.getOrDefault("restapi_id")
  valid_612127 = validateParameter(valid_612127, JString, required = true,
                                 default = nil)
  if valid_612127 != nil:
    section.add "restapi_id", valid_612127
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612128 = header.getOrDefault("X-Amz-Signature")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Signature", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Content-Sha256", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Date")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Date", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Credential")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Credential", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Security-Token")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Security-Token", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Algorithm")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Algorithm", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-SignedHeaders", valid_612134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612135: Call_GetGatewayResponse_612123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_612135.validator(path, query, header, formData, body)
  let scheme = call_612135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612135.url(scheme.get, call_612135.host, call_612135.base,
                         call_612135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612135, url, valid)

proc call*(call_612136: Call_GetGatewayResponse_612123; restapiId: string;
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
  var path_612137 = newJObject()
  add(path_612137, "response_type", newJString(responseType))
  add(path_612137, "restapi_id", newJString(restapiId))
  result = call_612136.call(path_612137, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_612123(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_612124, base: "/",
    url: url_GetGatewayResponse_612125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_612170 = ref object of OpenApiRestCall_610642
proc url_UpdateGatewayResponse_612172(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGatewayResponse_612171(path: JsonNode; query: JsonNode;
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
  var valid_612173 = path.getOrDefault("response_type")
  valid_612173 = validateParameter(valid_612173, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_612173 != nil:
    section.add "response_type", valid_612173
  var valid_612174 = path.getOrDefault("restapi_id")
  valid_612174 = validateParameter(valid_612174, JString, required = true,
                                 default = nil)
  if valid_612174 != nil:
    section.add "restapi_id", valid_612174
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612175 = header.getOrDefault("X-Amz-Signature")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "X-Amz-Signature", valid_612175
  var valid_612176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-Content-Sha256", valid_612176
  var valid_612177 = header.getOrDefault("X-Amz-Date")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Date", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Credential")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Credential", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Security-Token")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Security-Token", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Algorithm")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Algorithm", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-SignedHeaders", valid_612181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612183: Call_UpdateGatewayResponse_612170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_612183.validator(path, query, header, formData, body)
  let scheme = call_612183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612183.url(scheme.get, call_612183.host, call_612183.base,
                         call_612183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612183, url, valid)

proc call*(call_612184: Call_UpdateGatewayResponse_612170; restapiId: string;
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
  var path_612185 = newJObject()
  var body_612186 = newJObject()
  add(path_612185, "response_type", newJString(responseType))
  add(path_612185, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612186 = body
  result = call_612184.call(path_612185, nil, nil, nil, body_612186)

var updateGatewayResponse* = Call_UpdateGatewayResponse_612170(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_612171, base: "/",
    url: url_UpdateGatewayResponse_612172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_612155 = ref object of OpenApiRestCall_610642
proc url_DeleteGatewayResponse_612157(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGatewayResponse_612156(path: JsonNode; query: JsonNode;
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
  var valid_612158 = path.getOrDefault("response_type")
  valid_612158 = validateParameter(valid_612158, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_612158 != nil:
    section.add "response_type", valid_612158
  var valid_612159 = path.getOrDefault("restapi_id")
  valid_612159 = validateParameter(valid_612159, JString, required = true,
                                 default = nil)
  if valid_612159 != nil:
    section.add "restapi_id", valid_612159
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612160 = header.getOrDefault("X-Amz-Signature")
  valid_612160 = validateParameter(valid_612160, JString, required = false,
                                 default = nil)
  if valid_612160 != nil:
    section.add "X-Amz-Signature", valid_612160
  var valid_612161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612161 = validateParameter(valid_612161, JString, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "X-Amz-Content-Sha256", valid_612161
  var valid_612162 = header.getOrDefault("X-Amz-Date")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Date", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Credential")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Credential", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Security-Token")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Security-Token", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Algorithm")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Algorithm", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-SignedHeaders", valid_612166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612167: Call_DeleteGatewayResponse_612155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_612167.validator(path, query, header, formData, body)
  let scheme = call_612167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612167.url(scheme.get, call_612167.host, call_612167.base,
                         call_612167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612167, url, valid)

proc call*(call_612168: Call_DeleteGatewayResponse_612155; restapiId: string;
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
  var path_612169 = newJObject()
  add(path_612169, "response_type", newJString(responseType))
  add(path_612169, "restapi_id", newJString(restapiId))
  result = call_612168.call(path_612169, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_612155(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_612156, base: "/",
    url: url_DeleteGatewayResponse_612157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_612203 = ref object of OpenApiRestCall_610642
proc url_PutIntegration_612205(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutIntegration_612204(path: JsonNode; query: JsonNode;
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
  var valid_612206 = path.getOrDefault("restapi_id")
  valid_612206 = validateParameter(valid_612206, JString, required = true,
                                 default = nil)
  if valid_612206 != nil:
    section.add "restapi_id", valid_612206
  var valid_612207 = path.getOrDefault("resource_id")
  valid_612207 = validateParameter(valid_612207, JString, required = true,
                                 default = nil)
  if valid_612207 != nil:
    section.add "resource_id", valid_612207
  var valid_612208 = path.getOrDefault("http_method")
  valid_612208 = validateParameter(valid_612208, JString, required = true,
                                 default = nil)
  if valid_612208 != nil:
    section.add "http_method", valid_612208
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612209 = header.getOrDefault("X-Amz-Signature")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Signature", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Content-Sha256", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Date")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Date", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Credential")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Credential", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Security-Token")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Security-Token", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Algorithm")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Algorithm", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-SignedHeaders", valid_612215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612217: Call_PutIntegration_612203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_612217.validator(path, query, header, formData, body)
  let scheme = call_612217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612217.url(scheme.get, call_612217.host, call_612217.base,
                         call_612217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612217, url, valid)

proc call*(call_612218: Call_PutIntegration_612203; restapiId: string;
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
  var path_612219 = newJObject()
  var body_612220 = newJObject()
  add(path_612219, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612220 = body
  add(path_612219, "resource_id", newJString(resourceId))
  add(path_612219, "http_method", newJString(httpMethod))
  result = call_612218.call(path_612219, nil, nil, nil, body_612220)

var putIntegration* = Call_PutIntegration_612203(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_612204, base: "/", url: url_PutIntegration_612205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_612187 = ref object of OpenApiRestCall_610642
proc url_GetIntegration_612189(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegration_612188(path: JsonNode; query: JsonNode;
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
  var valid_612190 = path.getOrDefault("restapi_id")
  valid_612190 = validateParameter(valid_612190, JString, required = true,
                                 default = nil)
  if valid_612190 != nil:
    section.add "restapi_id", valid_612190
  var valid_612191 = path.getOrDefault("resource_id")
  valid_612191 = validateParameter(valid_612191, JString, required = true,
                                 default = nil)
  if valid_612191 != nil:
    section.add "resource_id", valid_612191
  var valid_612192 = path.getOrDefault("http_method")
  valid_612192 = validateParameter(valid_612192, JString, required = true,
                                 default = nil)
  if valid_612192 != nil:
    section.add "http_method", valid_612192
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612193 = header.getOrDefault("X-Amz-Signature")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "X-Amz-Signature", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Content-Sha256", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Date")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Date", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-Credential")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-Credential", valid_612196
  var valid_612197 = header.getOrDefault("X-Amz-Security-Token")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Security-Token", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Algorithm")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Algorithm", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-SignedHeaders", valid_612199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612200: Call_GetIntegration_612187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_612200.validator(path, query, header, formData, body)
  let scheme = call_612200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612200.url(scheme.get, call_612200.host, call_612200.base,
                         call_612200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612200, url, valid)

proc call*(call_612201: Call_GetIntegration_612187; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  var path_612202 = newJObject()
  add(path_612202, "restapi_id", newJString(restapiId))
  add(path_612202, "resource_id", newJString(resourceId))
  add(path_612202, "http_method", newJString(httpMethod))
  result = call_612201.call(path_612202, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_612187(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_612188, base: "/", url: url_GetIntegration_612189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_612237 = ref object of OpenApiRestCall_610642
proc url_UpdateIntegration_612239(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegration_612238(path: JsonNode; query: JsonNode;
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
  var valid_612240 = path.getOrDefault("restapi_id")
  valid_612240 = validateParameter(valid_612240, JString, required = true,
                                 default = nil)
  if valid_612240 != nil:
    section.add "restapi_id", valid_612240
  var valid_612241 = path.getOrDefault("resource_id")
  valid_612241 = validateParameter(valid_612241, JString, required = true,
                                 default = nil)
  if valid_612241 != nil:
    section.add "resource_id", valid_612241
  var valid_612242 = path.getOrDefault("http_method")
  valid_612242 = validateParameter(valid_612242, JString, required = true,
                                 default = nil)
  if valid_612242 != nil:
    section.add "http_method", valid_612242
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612243 = header.getOrDefault("X-Amz-Signature")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Signature", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Content-Sha256", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Date")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Date", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Credential")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Credential", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Security-Token")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Security-Token", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-Algorithm")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-Algorithm", valid_612248
  var valid_612249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "X-Amz-SignedHeaders", valid_612249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612251: Call_UpdateIntegration_612237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_612251.validator(path, query, header, formData, body)
  let scheme = call_612251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612251.url(scheme.get, call_612251.host, call_612251.base,
                         call_612251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612251, url, valid)

proc call*(call_612252: Call_UpdateIntegration_612237; restapiId: string;
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
  var path_612253 = newJObject()
  var body_612254 = newJObject()
  add(path_612253, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612254 = body
  add(path_612253, "resource_id", newJString(resourceId))
  add(path_612253, "http_method", newJString(httpMethod))
  result = call_612252.call(path_612253, nil, nil, nil, body_612254)

var updateIntegration* = Call_UpdateIntegration_612237(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_612238, base: "/",
    url: url_UpdateIntegration_612239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_612221 = ref object of OpenApiRestCall_610642
proc url_DeleteIntegration_612223(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegration_612222(path: JsonNode; query: JsonNode;
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
  var valid_612224 = path.getOrDefault("restapi_id")
  valid_612224 = validateParameter(valid_612224, JString, required = true,
                                 default = nil)
  if valid_612224 != nil:
    section.add "restapi_id", valid_612224
  var valid_612225 = path.getOrDefault("resource_id")
  valid_612225 = validateParameter(valid_612225, JString, required = true,
                                 default = nil)
  if valid_612225 != nil:
    section.add "resource_id", valid_612225
  var valid_612226 = path.getOrDefault("http_method")
  valid_612226 = validateParameter(valid_612226, JString, required = true,
                                 default = nil)
  if valid_612226 != nil:
    section.add "http_method", valid_612226
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_612234: Call_DeleteIntegration_612221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_612234.validator(path, query, header, formData, body)
  let scheme = call_612234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612234.url(scheme.get, call_612234.host, call_612234.base,
                         call_612234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612234, url, valid)

proc call*(call_612235: Call_DeleteIntegration_612221; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  var path_612236 = newJObject()
  add(path_612236, "restapi_id", newJString(restapiId))
  add(path_612236, "resource_id", newJString(resourceId))
  add(path_612236, "http_method", newJString(httpMethod))
  result = call_612235.call(path_612236, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_612221(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_612222, base: "/",
    url: url_DeleteIntegration_612223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_612272 = ref object of OpenApiRestCall_610642
proc url_PutIntegrationResponse_612274(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutIntegrationResponse_612273(path: JsonNode; query: JsonNode;
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
  var valid_612275 = path.getOrDefault("status_code")
  valid_612275 = validateParameter(valid_612275, JString, required = true,
                                 default = nil)
  if valid_612275 != nil:
    section.add "status_code", valid_612275
  var valid_612276 = path.getOrDefault("restapi_id")
  valid_612276 = validateParameter(valid_612276, JString, required = true,
                                 default = nil)
  if valid_612276 != nil:
    section.add "restapi_id", valid_612276
  var valid_612277 = path.getOrDefault("resource_id")
  valid_612277 = validateParameter(valid_612277, JString, required = true,
                                 default = nil)
  if valid_612277 != nil:
    section.add "resource_id", valid_612277
  var valid_612278 = path.getOrDefault("http_method")
  valid_612278 = validateParameter(valid_612278, JString, required = true,
                                 default = nil)
  if valid_612278 != nil:
    section.add "http_method", valid_612278
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612279 = header.getOrDefault("X-Amz-Signature")
  valid_612279 = validateParameter(valid_612279, JString, required = false,
                                 default = nil)
  if valid_612279 != nil:
    section.add "X-Amz-Signature", valid_612279
  var valid_612280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "X-Amz-Content-Sha256", valid_612280
  var valid_612281 = header.getOrDefault("X-Amz-Date")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "X-Amz-Date", valid_612281
  var valid_612282 = header.getOrDefault("X-Amz-Credential")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "X-Amz-Credential", valid_612282
  var valid_612283 = header.getOrDefault("X-Amz-Security-Token")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Security-Token", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Algorithm")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Algorithm", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-SignedHeaders", valid_612285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612287: Call_PutIntegrationResponse_612272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_612287.validator(path, query, header, formData, body)
  let scheme = call_612287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612287.url(scheme.get, call_612287.host, call_612287.base,
                         call_612287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612287, url, valid)

proc call*(call_612288: Call_PutIntegrationResponse_612272; statusCode: string;
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
  var path_612289 = newJObject()
  var body_612290 = newJObject()
  add(path_612289, "status_code", newJString(statusCode))
  add(path_612289, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612290 = body
  add(path_612289, "resource_id", newJString(resourceId))
  add(path_612289, "http_method", newJString(httpMethod))
  result = call_612288.call(path_612289, nil, nil, nil, body_612290)

var putIntegrationResponse* = Call_PutIntegrationResponse_612272(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_612273, base: "/",
    url: url_PutIntegrationResponse_612274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_612255 = ref object of OpenApiRestCall_610642
proc url_GetIntegrationResponse_612257(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponse_612256(path: JsonNode; query: JsonNode;
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
  var valid_612258 = path.getOrDefault("status_code")
  valid_612258 = validateParameter(valid_612258, JString, required = true,
                                 default = nil)
  if valid_612258 != nil:
    section.add "status_code", valid_612258
  var valid_612259 = path.getOrDefault("restapi_id")
  valid_612259 = validateParameter(valid_612259, JString, required = true,
                                 default = nil)
  if valid_612259 != nil:
    section.add "restapi_id", valid_612259
  var valid_612260 = path.getOrDefault("resource_id")
  valid_612260 = validateParameter(valid_612260, JString, required = true,
                                 default = nil)
  if valid_612260 != nil:
    section.add "resource_id", valid_612260
  var valid_612261 = path.getOrDefault("http_method")
  valid_612261 = validateParameter(valid_612261, JString, required = true,
                                 default = nil)
  if valid_612261 != nil:
    section.add "http_method", valid_612261
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612262 = header.getOrDefault("X-Amz-Signature")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-Signature", valid_612262
  var valid_612263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612263 = validateParameter(valid_612263, JString, required = false,
                                 default = nil)
  if valid_612263 != nil:
    section.add "X-Amz-Content-Sha256", valid_612263
  var valid_612264 = header.getOrDefault("X-Amz-Date")
  valid_612264 = validateParameter(valid_612264, JString, required = false,
                                 default = nil)
  if valid_612264 != nil:
    section.add "X-Amz-Date", valid_612264
  var valid_612265 = header.getOrDefault("X-Amz-Credential")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-Credential", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-Security-Token")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Security-Token", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Algorithm")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Algorithm", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-SignedHeaders", valid_612268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612269: Call_GetIntegrationResponse_612255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_612269.validator(path, query, header, formData, body)
  let scheme = call_612269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612269.url(scheme.get, call_612269.host, call_612269.base,
                         call_612269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612269, url, valid)

proc call*(call_612270: Call_GetIntegrationResponse_612255; statusCode: string;
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
  var path_612271 = newJObject()
  add(path_612271, "status_code", newJString(statusCode))
  add(path_612271, "restapi_id", newJString(restapiId))
  add(path_612271, "resource_id", newJString(resourceId))
  add(path_612271, "http_method", newJString(httpMethod))
  result = call_612270.call(path_612271, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_612255(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_612256, base: "/",
    url: url_GetIntegrationResponse_612257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_612308 = ref object of OpenApiRestCall_610642
proc url_UpdateIntegrationResponse_612310(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_612309(path: JsonNode; query: JsonNode;
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
  var valid_612311 = path.getOrDefault("status_code")
  valid_612311 = validateParameter(valid_612311, JString, required = true,
                                 default = nil)
  if valid_612311 != nil:
    section.add "status_code", valid_612311
  var valid_612312 = path.getOrDefault("restapi_id")
  valid_612312 = validateParameter(valid_612312, JString, required = true,
                                 default = nil)
  if valid_612312 != nil:
    section.add "restapi_id", valid_612312
  var valid_612313 = path.getOrDefault("resource_id")
  valid_612313 = validateParameter(valid_612313, JString, required = true,
                                 default = nil)
  if valid_612313 != nil:
    section.add "resource_id", valid_612313
  var valid_612314 = path.getOrDefault("http_method")
  valid_612314 = validateParameter(valid_612314, JString, required = true,
                                 default = nil)
  if valid_612314 != nil:
    section.add "http_method", valid_612314
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612315 = header.getOrDefault("X-Amz-Signature")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "X-Amz-Signature", valid_612315
  var valid_612316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Content-Sha256", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Date")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Date", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Credential")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Credential", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Security-Token")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Security-Token", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Algorithm")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Algorithm", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-SignedHeaders", valid_612321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612323: Call_UpdateIntegrationResponse_612308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_612323.validator(path, query, header, formData, body)
  let scheme = call_612323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612323.url(scheme.get, call_612323.host, call_612323.base,
                         call_612323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612323, url, valid)

proc call*(call_612324: Call_UpdateIntegrationResponse_612308; statusCode: string;
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
  var path_612325 = newJObject()
  var body_612326 = newJObject()
  add(path_612325, "status_code", newJString(statusCode))
  add(path_612325, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612326 = body
  add(path_612325, "resource_id", newJString(resourceId))
  add(path_612325, "http_method", newJString(httpMethod))
  result = call_612324.call(path_612325, nil, nil, nil, body_612326)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_612308(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_612309, base: "/",
    url: url_UpdateIntegrationResponse_612310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_612291 = ref object of OpenApiRestCall_610642
proc url_DeleteIntegrationResponse_612293(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_612292(path: JsonNode; query: JsonNode;
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
  var valid_612294 = path.getOrDefault("status_code")
  valid_612294 = validateParameter(valid_612294, JString, required = true,
                                 default = nil)
  if valid_612294 != nil:
    section.add "status_code", valid_612294
  var valid_612295 = path.getOrDefault("restapi_id")
  valid_612295 = validateParameter(valid_612295, JString, required = true,
                                 default = nil)
  if valid_612295 != nil:
    section.add "restapi_id", valid_612295
  var valid_612296 = path.getOrDefault("resource_id")
  valid_612296 = validateParameter(valid_612296, JString, required = true,
                                 default = nil)
  if valid_612296 != nil:
    section.add "resource_id", valid_612296
  var valid_612297 = path.getOrDefault("http_method")
  valid_612297 = validateParameter(valid_612297, JString, required = true,
                                 default = nil)
  if valid_612297 != nil:
    section.add "http_method", valid_612297
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612298 = header.getOrDefault("X-Amz-Signature")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-Signature", valid_612298
  var valid_612299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612299 = validateParameter(valid_612299, JString, required = false,
                                 default = nil)
  if valid_612299 != nil:
    section.add "X-Amz-Content-Sha256", valid_612299
  var valid_612300 = header.getOrDefault("X-Amz-Date")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Date", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Credential")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Credential", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Security-Token")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Security-Token", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Algorithm")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Algorithm", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-SignedHeaders", valid_612304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612305: Call_DeleteIntegrationResponse_612291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_612305.validator(path, query, header, formData, body)
  let scheme = call_612305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612305.url(scheme.get, call_612305.host, call_612305.base,
                         call_612305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612305, url, valid)

proc call*(call_612306: Call_DeleteIntegrationResponse_612291; statusCode: string;
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
  var path_612307 = newJObject()
  add(path_612307, "status_code", newJString(statusCode))
  add(path_612307, "restapi_id", newJString(restapiId))
  add(path_612307, "resource_id", newJString(resourceId))
  add(path_612307, "http_method", newJString(httpMethod))
  result = call_612306.call(path_612307, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_612291(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_612292, base: "/",
    url: url_DeleteIntegrationResponse_612293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_612343 = ref object of OpenApiRestCall_610642
proc url_PutMethod_612345(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutMethod_612344(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612346 = path.getOrDefault("restapi_id")
  valid_612346 = validateParameter(valid_612346, JString, required = true,
                                 default = nil)
  if valid_612346 != nil:
    section.add "restapi_id", valid_612346
  var valid_612347 = path.getOrDefault("resource_id")
  valid_612347 = validateParameter(valid_612347, JString, required = true,
                                 default = nil)
  if valid_612347 != nil:
    section.add "resource_id", valid_612347
  var valid_612348 = path.getOrDefault("http_method")
  valid_612348 = validateParameter(valid_612348, JString, required = true,
                                 default = nil)
  if valid_612348 != nil:
    section.add "http_method", valid_612348
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612349 = header.getOrDefault("X-Amz-Signature")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Signature", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Content-Sha256", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Date")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Date", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-Credential")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Credential", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Security-Token")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Security-Token", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-Algorithm")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-Algorithm", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-SignedHeaders", valid_612355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612357: Call_PutMethod_612343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_612357.validator(path, query, header, formData, body)
  let scheme = call_612357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612357.url(scheme.get, call_612357.host, call_612357.base,
                         call_612357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612357, url, valid)

proc call*(call_612358: Call_PutMethod_612343; restapiId: string; body: JsonNode;
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
  var path_612359 = newJObject()
  var body_612360 = newJObject()
  add(path_612359, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612360 = body
  add(path_612359, "resource_id", newJString(resourceId))
  add(path_612359, "http_method", newJString(httpMethod))
  result = call_612358.call(path_612359, nil, nil, nil, body_612360)

var putMethod* = Call_PutMethod_612343(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_612344,
                                    base: "/", url: url_PutMethod_612345,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_612361 = ref object of OpenApiRestCall_610642
proc url_TestInvokeMethod_612363(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TestInvokeMethod_612362(path: JsonNode; query: JsonNode;
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
  var valid_612364 = path.getOrDefault("restapi_id")
  valid_612364 = validateParameter(valid_612364, JString, required = true,
                                 default = nil)
  if valid_612364 != nil:
    section.add "restapi_id", valid_612364
  var valid_612365 = path.getOrDefault("resource_id")
  valid_612365 = validateParameter(valid_612365, JString, required = true,
                                 default = nil)
  if valid_612365 != nil:
    section.add "resource_id", valid_612365
  var valid_612366 = path.getOrDefault("http_method")
  valid_612366 = validateParameter(valid_612366, JString, required = true,
                                 default = nil)
  if valid_612366 != nil:
    section.add "http_method", valid_612366
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612367 = header.getOrDefault("X-Amz-Signature")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-Signature", valid_612367
  var valid_612368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-Content-Sha256", valid_612368
  var valid_612369 = header.getOrDefault("X-Amz-Date")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-Date", valid_612369
  var valid_612370 = header.getOrDefault("X-Amz-Credential")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Credential", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Security-Token")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Security-Token", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Algorithm")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Algorithm", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-SignedHeaders", valid_612373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612375: Call_TestInvokeMethod_612361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_612375.validator(path, query, header, formData, body)
  let scheme = call_612375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612375.url(scheme.get, call_612375.host, call_612375.base,
                         call_612375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612375, url, valid)

proc call*(call_612376: Call_TestInvokeMethod_612361; restapiId: string;
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
  var path_612377 = newJObject()
  var body_612378 = newJObject()
  add(path_612377, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612378 = body
  add(path_612377, "resource_id", newJString(resourceId))
  add(path_612377, "http_method", newJString(httpMethod))
  result = call_612376.call(path_612377, nil, nil, nil, body_612378)

var testInvokeMethod* = Call_TestInvokeMethod_612361(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_612362, base: "/",
    url: url_TestInvokeMethod_612363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_612327 = ref object of OpenApiRestCall_610642
proc url_GetMethod_612329(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMethod_612328(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612330 = path.getOrDefault("restapi_id")
  valid_612330 = validateParameter(valid_612330, JString, required = true,
                                 default = nil)
  if valid_612330 != nil:
    section.add "restapi_id", valid_612330
  var valid_612331 = path.getOrDefault("resource_id")
  valid_612331 = validateParameter(valid_612331, JString, required = true,
                                 default = nil)
  if valid_612331 != nil:
    section.add "resource_id", valid_612331
  var valid_612332 = path.getOrDefault("http_method")
  valid_612332 = validateParameter(valid_612332, JString, required = true,
                                 default = nil)
  if valid_612332 != nil:
    section.add "http_method", valid_612332
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612333 = header.getOrDefault("X-Amz-Signature")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Signature", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Content-Sha256", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Date")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Date", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Credential")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Credential", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Security-Token")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Security-Token", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Algorithm")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Algorithm", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-SignedHeaders", valid_612339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612340: Call_GetMethod_612327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_612340.validator(path, query, header, formData, body)
  let scheme = call_612340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612340.url(scheme.get, call_612340.host, call_612340.base,
                         call_612340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612340, url, valid)

proc call*(call_612341: Call_GetMethod_612327; restapiId: string; resourceId: string;
          httpMethod: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  var path_612342 = newJObject()
  add(path_612342, "restapi_id", newJString(restapiId))
  add(path_612342, "resource_id", newJString(resourceId))
  add(path_612342, "http_method", newJString(httpMethod))
  result = call_612341.call(path_612342, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_612327(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_612328,
                                    base: "/", url: url_GetMethod_612329,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_612395 = ref object of OpenApiRestCall_610642
proc url_UpdateMethod_612397(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMethod_612396(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612398 = path.getOrDefault("restapi_id")
  valid_612398 = validateParameter(valid_612398, JString, required = true,
                                 default = nil)
  if valid_612398 != nil:
    section.add "restapi_id", valid_612398
  var valid_612399 = path.getOrDefault("resource_id")
  valid_612399 = validateParameter(valid_612399, JString, required = true,
                                 default = nil)
  if valid_612399 != nil:
    section.add "resource_id", valid_612399
  var valid_612400 = path.getOrDefault("http_method")
  valid_612400 = validateParameter(valid_612400, JString, required = true,
                                 default = nil)
  if valid_612400 != nil:
    section.add "http_method", valid_612400
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612401 = header.getOrDefault("X-Amz-Signature")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "X-Amz-Signature", valid_612401
  var valid_612402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "X-Amz-Content-Sha256", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-Date")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-Date", valid_612403
  var valid_612404 = header.getOrDefault("X-Amz-Credential")
  valid_612404 = validateParameter(valid_612404, JString, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "X-Amz-Credential", valid_612404
  var valid_612405 = header.getOrDefault("X-Amz-Security-Token")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Security-Token", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Algorithm")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Algorithm", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-SignedHeaders", valid_612407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612409: Call_UpdateMethod_612395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_612409.validator(path, query, header, formData, body)
  let scheme = call_612409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612409.url(scheme.get, call_612409.host, call_612409.base,
                         call_612409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612409, url, valid)

proc call*(call_612410: Call_UpdateMethod_612395; restapiId: string; body: JsonNode;
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
  var path_612411 = newJObject()
  var body_612412 = newJObject()
  add(path_612411, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612412 = body
  add(path_612411, "resource_id", newJString(resourceId))
  add(path_612411, "http_method", newJString(httpMethod))
  result = call_612410.call(path_612411, nil, nil, nil, body_612412)

var updateMethod* = Call_UpdateMethod_612395(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_612396, base: "/", url: url_UpdateMethod_612397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_612379 = ref object of OpenApiRestCall_610642
proc url_DeleteMethod_612381(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMethod_612380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612382 = path.getOrDefault("restapi_id")
  valid_612382 = validateParameter(valid_612382, JString, required = true,
                                 default = nil)
  if valid_612382 != nil:
    section.add "restapi_id", valid_612382
  var valid_612383 = path.getOrDefault("resource_id")
  valid_612383 = validateParameter(valid_612383, JString, required = true,
                                 default = nil)
  if valid_612383 != nil:
    section.add "resource_id", valid_612383
  var valid_612384 = path.getOrDefault("http_method")
  valid_612384 = validateParameter(valid_612384, JString, required = true,
                                 default = nil)
  if valid_612384 != nil:
    section.add "http_method", valid_612384
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612385 = header.getOrDefault("X-Amz-Signature")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-Signature", valid_612385
  var valid_612386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "X-Amz-Content-Sha256", valid_612386
  var valid_612387 = header.getOrDefault("X-Amz-Date")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "X-Amz-Date", valid_612387
  var valid_612388 = header.getOrDefault("X-Amz-Credential")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Credential", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-Security-Token")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-Security-Token", valid_612389
  var valid_612390 = header.getOrDefault("X-Amz-Algorithm")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Algorithm", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-SignedHeaders", valid_612391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612392: Call_DeleteMethod_612379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_612392.validator(path, query, header, formData, body)
  let scheme = call_612392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612392.url(scheme.get, call_612392.host, call_612392.base,
                         call_612392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612392, url, valid)

proc call*(call_612393: Call_DeleteMethod_612379; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_612394 = newJObject()
  add(path_612394, "restapi_id", newJString(restapiId))
  add(path_612394, "resource_id", newJString(resourceId))
  add(path_612394, "http_method", newJString(httpMethod))
  result = call_612393.call(path_612394, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_612379(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_612380, base: "/", url: url_DeleteMethod_612381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_612430 = ref object of OpenApiRestCall_610642
proc url_PutMethodResponse_612432(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutMethodResponse_612431(path: JsonNode; query: JsonNode;
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
  var valid_612433 = path.getOrDefault("status_code")
  valid_612433 = validateParameter(valid_612433, JString, required = true,
                                 default = nil)
  if valid_612433 != nil:
    section.add "status_code", valid_612433
  var valid_612434 = path.getOrDefault("restapi_id")
  valid_612434 = validateParameter(valid_612434, JString, required = true,
                                 default = nil)
  if valid_612434 != nil:
    section.add "restapi_id", valid_612434
  var valid_612435 = path.getOrDefault("resource_id")
  valid_612435 = validateParameter(valid_612435, JString, required = true,
                                 default = nil)
  if valid_612435 != nil:
    section.add "resource_id", valid_612435
  var valid_612436 = path.getOrDefault("http_method")
  valid_612436 = validateParameter(valid_612436, JString, required = true,
                                 default = nil)
  if valid_612436 != nil:
    section.add "http_method", valid_612436
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612437 = header.getOrDefault("X-Amz-Signature")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Signature", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Content-Sha256", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-Date")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Date", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Credential")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Credential", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Security-Token")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Security-Token", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Algorithm")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Algorithm", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-SignedHeaders", valid_612443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612445: Call_PutMethodResponse_612430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_612445.validator(path, query, header, formData, body)
  let scheme = call_612445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612445.url(scheme.get, call_612445.host, call_612445.base,
                         call_612445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612445, url, valid)

proc call*(call_612446: Call_PutMethodResponse_612430; statusCode: string;
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
  var path_612447 = newJObject()
  var body_612448 = newJObject()
  add(path_612447, "status_code", newJString(statusCode))
  add(path_612447, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612448 = body
  add(path_612447, "resource_id", newJString(resourceId))
  add(path_612447, "http_method", newJString(httpMethod))
  result = call_612446.call(path_612447, nil, nil, nil, body_612448)

var putMethodResponse* = Call_PutMethodResponse_612430(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_612431, base: "/",
    url: url_PutMethodResponse_612432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_612413 = ref object of OpenApiRestCall_610642
proc url_GetMethodResponse_612415(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMethodResponse_612414(path: JsonNode; query: JsonNode;
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
  var valid_612416 = path.getOrDefault("status_code")
  valid_612416 = validateParameter(valid_612416, JString, required = true,
                                 default = nil)
  if valid_612416 != nil:
    section.add "status_code", valid_612416
  var valid_612417 = path.getOrDefault("restapi_id")
  valid_612417 = validateParameter(valid_612417, JString, required = true,
                                 default = nil)
  if valid_612417 != nil:
    section.add "restapi_id", valid_612417
  var valid_612418 = path.getOrDefault("resource_id")
  valid_612418 = validateParameter(valid_612418, JString, required = true,
                                 default = nil)
  if valid_612418 != nil:
    section.add "resource_id", valid_612418
  var valid_612419 = path.getOrDefault("http_method")
  valid_612419 = validateParameter(valid_612419, JString, required = true,
                                 default = nil)
  if valid_612419 != nil:
    section.add "http_method", valid_612419
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612420 = header.getOrDefault("X-Amz-Signature")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Signature", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Content-Sha256", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Date")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Date", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Credential")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Credential", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-Security-Token")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Security-Token", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Algorithm")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Algorithm", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-SignedHeaders", valid_612426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612427: Call_GetMethodResponse_612413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_612427.validator(path, query, header, formData, body)
  let scheme = call_612427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612427.url(scheme.get, call_612427.host, call_612427.base,
                         call_612427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612427, url, valid)

proc call*(call_612428: Call_GetMethodResponse_612413; statusCode: string;
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
  var path_612429 = newJObject()
  add(path_612429, "status_code", newJString(statusCode))
  add(path_612429, "restapi_id", newJString(restapiId))
  add(path_612429, "resource_id", newJString(resourceId))
  add(path_612429, "http_method", newJString(httpMethod))
  result = call_612428.call(path_612429, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_612413(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_612414, base: "/",
    url: url_GetMethodResponse_612415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_612466 = ref object of OpenApiRestCall_610642
proc url_UpdateMethodResponse_612468(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMethodResponse_612467(path: JsonNode; query: JsonNode;
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
  var valid_612469 = path.getOrDefault("status_code")
  valid_612469 = validateParameter(valid_612469, JString, required = true,
                                 default = nil)
  if valid_612469 != nil:
    section.add "status_code", valid_612469
  var valid_612470 = path.getOrDefault("restapi_id")
  valid_612470 = validateParameter(valid_612470, JString, required = true,
                                 default = nil)
  if valid_612470 != nil:
    section.add "restapi_id", valid_612470
  var valid_612471 = path.getOrDefault("resource_id")
  valid_612471 = validateParameter(valid_612471, JString, required = true,
                                 default = nil)
  if valid_612471 != nil:
    section.add "resource_id", valid_612471
  var valid_612472 = path.getOrDefault("http_method")
  valid_612472 = validateParameter(valid_612472, JString, required = true,
                                 default = nil)
  if valid_612472 != nil:
    section.add "http_method", valid_612472
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612473 = header.getOrDefault("X-Amz-Signature")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Signature", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Content-Sha256", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-Date")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-Date", valid_612475
  var valid_612476 = header.getOrDefault("X-Amz-Credential")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "X-Amz-Credential", valid_612476
  var valid_612477 = header.getOrDefault("X-Amz-Security-Token")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "X-Amz-Security-Token", valid_612477
  var valid_612478 = header.getOrDefault("X-Amz-Algorithm")
  valid_612478 = validateParameter(valid_612478, JString, required = false,
                                 default = nil)
  if valid_612478 != nil:
    section.add "X-Amz-Algorithm", valid_612478
  var valid_612479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612479 = validateParameter(valid_612479, JString, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "X-Amz-SignedHeaders", valid_612479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612481: Call_UpdateMethodResponse_612466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_612481.validator(path, query, header, formData, body)
  let scheme = call_612481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612481.url(scheme.get, call_612481.host, call_612481.base,
                         call_612481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612481, url, valid)

proc call*(call_612482: Call_UpdateMethodResponse_612466; statusCode: string;
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
  var path_612483 = newJObject()
  var body_612484 = newJObject()
  add(path_612483, "status_code", newJString(statusCode))
  add(path_612483, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612484 = body
  add(path_612483, "resource_id", newJString(resourceId))
  add(path_612483, "http_method", newJString(httpMethod))
  result = call_612482.call(path_612483, nil, nil, nil, body_612484)

var updateMethodResponse* = Call_UpdateMethodResponse_612466(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_612467, base: "/",
    url: url_UpdateMethodResponse_612468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_612449 = ref object of OpenApiRestCall_610642
proc url_DeleteMethodResponse_612451(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMethodResponse_612450(path: JsonNode; query: JsonNode;
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
  var valid_612452 = path.getOrDefault("status_code")
  valid_612452 = validateParameter(valid_612452, JString, required = true,
                                 default = nil)
  if valid_612452 != nil:
    section.add "status_code", valid_612452
  var valid_612453 = path.getOrDefault("restapi_id")
  valid_612453 = validateParameter(valid_612453, JString, required = true,
                                 default = nil)
  if valid_612453 != nil:
    section.add "restapi_id", valid_612453
  var valid_612454 = path.getOrDefault("resource_id")
  valid_612454 = validateParameter(valid_612454, JString, required = true,
                                 default = nil)
  if valid_612454 != nil:
    section.add "resource_id", valid_612454
  var valid_612455 = path.getOrDefault("http_method")
  valid_612455 = validateParameter(valid_612455, JString, required = true,
                                 default = nil)
  if valid_612455 != nil:
    section.add "http_method", valid_612455
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612456 = header.getOrDefault("X-Amz-Signature")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Signature", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Content-Sha256", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-Date")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-Date", valid_612458
  var valid_612459 = header.getOrDefault("X-Amz-Credential")
  valid_612459 = validateParameter(valid_612459, JString, required = false,
                                 default = nil)
  if valid_612459 != nil:
    section.add "X-Amz-Credential", valid_612459
  var valid_612460 = header.getOrDefault("X-Amz-Security-Token")
  valid_612460 = validateParameter(valid_612460, JString, required = false,
                                 default = nil)
  if valid_612460 != nil:
    section.add "X-Amz-Security-Token", valid_612460
  var valid_612461 = header.getOrDefault("X-Amz-Algorithm")
  valid_612461 = validateParameter(valid_612461, JString, required = false,
                                 default = nil)
  if valid_612461 != nil:
    section.add "X-Amz-Algorithm", valid_612461
  var valid_612462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612462 = validateParameter(valid_612462, JString, required = false,
                                 default = nil)
  if valid_612462 != nil:
    section.add "X-Amz-SignedHeaders", valid_612462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612463: Call_DeleteMethodResponse_612449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_612463.validator(path, query, header, formData, body)
  let scheme = call_612463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612463.url(scheme.get, call_612463.host, call_612463.base,
                         call_612463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612463, url, valid)

proc call*(call_612464: Call_DeleteMethodResponse_612449; statusCode: string;
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
  var path_612465 = newJObject()
  add(path_612465, "status_code", newJString(statusCode))
  add(path_612465, "restapi_id", newJString(restapiId))
  add(path_612465, "resource_id", newJString(resourceId))
  add(path_612465, "http_method", newJString(httpMethod))
  result = call_612464.call(path_612465, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_612449(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_612450, base: "/",
    url: url_DeleteMethodResponse_612451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_612485 = ref object of OpenApiRestCall_610642
proc url_GetModel_612487(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModel_612486(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612488 = path.getOrDefault("model_name")
  valid_612488 = validateParameter(valid_612488, JString, required = true,
                                 default = nil)
  if valid_612488 != nil:
    section.add "model_name", valid_612488
  var valid_612489 = path.getOrDefault("restapi_id")
  valid_612489 = validateParameter(valid_612489, JString, required = true,
                                 default = nil)
  if valid_612489 != nil:
    section.add "restapi_id", valid_612489
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_612490 = query.getOrDefault("flatten")
  valid_612490 = validateParameter(valid_612490, JBool, required = false, default = nil)
  if valid_612490 != nil:
    section.add "flatten", valid_612490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612491 = header.getOrDefault("X-Amz-Signature")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Signature", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-Content-Sha256", valid_612492
  var valid_612493 = header.getOrDefault("X-Amz-Date")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "X-Amz-Date", valid_612493
  var valid_612494 = header.getOrDefault("X-Amz-Credential")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "X-Amz-Credential", valid_612494
  var valid_612495 = header.getOrDefault("X-Amz-Security-Token")
  valid_612495 = validateParameter(valid_612495, JString, required = false,
                                 default = nil)
  if valid_612495 != nil:
    section.add "X-Amz-Security-Token", valid_612495
  var valid_612496 = header.getOrDefault("X-Amz-Algorithm")
  valid_612496 = validateParameter(valid_612496, JString, required = false,
                                 default = nil)
  if valid_612496 != nil:
    section.add "X-Amz-Algorithm", valid_612496
  var valid_612497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612497 = validateParameter(valid_612497, JString, required = false,
                                 default = nil)
  if valid_612497 != nil:
    section.add "X-Amz-SignedHeaders", valid_612497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612498: Call_GetModel_612485; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_612498.validator(path, query, header, formData, body)
  let scheme = call_612498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612498.url(scheme.get, call_612498.host, call_612498.base,
                         call_612498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612498, url, valid)

proc call*(call_612499: Call_GetModel_612485; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_612500 = newJObject()
  var query_612501 = newJObject()
  add(query_612501, "flatten", newJBool(flatten))
  add(path_612500, "model_name", newJString(modelName))
  add(path_612500, "restapi_id", newJString(restapiId))
  result = call_612499.call(path_612500, query_612501, nil, nil, nil)

var getModel* = Call_GetModel_612485(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_612486, base: "/",
                                  url: url_GetModel_612487,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_612517 = ref object of OpenApiRestCall_610642
proc url_UpdateModel_612519(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateModel_612518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612520 = path.getOrDefault("model_name")
  valid_612520 = validateParameter(valid_612520, JString, required = true,
                                 default = nil)
  if valid_612520 != nil:
    section.add "model_name", valid_612520
  var valid_612521 = path.getOrDefault("restapi_id")
  valid_612521 = validateParameter(valid_612521, JString, required = true,
                                 default = nil)
  if valid_612521 != nil:
    section.add "restapi_id", valid_612521
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612522 = header.getOrDefault("X-Amz-Signature")
  valid_612522 = validateParameter(valid_612522, JString, required = false,
                                 default = nil)
  if valid_612522 != nil:
    section.add "X-Amz-Signature", valid_612522
  var valid_612523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612523 = validateParameter(valid_612523, JString, required = false,
                                 default = nil)
  if valid_612523 != nil:
    section.add "X-Amz-Content-Sha256", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-Date")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-Date", valid_612524
  var valid_612525 = header.getOrDefault("X-Amz-Credential")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = nil)
  if valid_612525 != nil:
    section.add "X-Amz-Credential", valid_612525
  var valid_612526 = header.getOrDefault("X-Amz-Security-Token")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "X-Amz-Security-Token", valid_612526
  var valid_612527 = header.getOrDefault("X-Amz-Algorithm")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "X-Amz-Algorithm", valid_612527
  var valid_612528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "X-Amz-SignedHeaders", valid_612528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612530: Call_UpdateModel_612517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_612530.validator(path, query, header, formData, body)
  let scheme = call_612530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612530.url(scheme.get, call_612530.host, call_612530.base,
                         call_612530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612530, url, valid)

proc call*(call_612531: Call_UpdateModel_612517; modelName: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_612532 = newJObject()
  var body_612533 = newJObject()
  add(path_612532, "model_name", newJString(modelName))
  add(path_612532, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612533 = body
  result = call_612531.call(path_612532, nil, nil, nil, body_612533)

var updateModel* = Call_UpdateModel_612517(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_612518,
                                        base: "/", url: url_UpdateModel_612519,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_612502 = ref object of OpenApiRestCall_610642
proc url_DeleteModel_612504(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteModel_612503(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612505 = path.getOrDefault("model_name")
  valid_612505 = validateParameter(valid_612505, JString, required = true,
                                 default = nil)
  if valid_612505 != nil:
    section.add "model_name", valid_612505
  var valid_612506 = path.getOrDefault("restapi_id")
  valid_612506 = validateParameter(valid_612506, JString, required = true,
                                 default = nil)
  if valid_612506 != nil:
    section.add "restapi_id", valid_612506
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612507 = header.getOrDefault("X-Amz-Signature")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Signature", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Content-Sha256", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Date")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Date", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Credential")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Credential", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-Security-Token")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-Security-Token", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-Algorithm")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-Algorithm", valid_612512
  var valid_612513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612513 = validateParameter(valid_612513, JString, required = false,
                                 default = nil)
  if valid_612513 != nil:
    section.add "X-Amz-SignedHeaders", valid_612513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612514: Call_DeleteModel_612502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_612514.validator(path, query, header, formData, body)
  let scheme = call_612514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612514.url(scheme.get, call_612514.host, call_612514.base,
                         call_612514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612514, url, valid)

proc call*(call_612515: Call_DeleteModel_612502; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_612516 = newJObject()
  add(path_612516, "model_name", newJString(modelName))
  add(path_612516, "restapi_id", newJString(restapiId))
  result = call_612515.call(path_612516, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_612502(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_612503,
                                        base: "/", url: url_DeleteModel_612504,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_612534 = ref object of OpenApiRestCall_610642
proc url_GetRequestValidator_612536(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRequestValidator_612535(path: JsonNode; query: JsonNode;
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
  var valid_612537 = path.getOrDefault("restapi_id")
  valid_612537 = validateParameter(valid_612537, JString, required = true,
                                 default = nil)
  if valid_612537 != nil:
    section.add "restapi_id", valid_612537
  var valid_612538 = path.getOrDefault("requestvalidator_id")
  valid_612538 = validateParameter(valid_612538, JString, required = true,
                                 default = nil)
  if valid_612538 != nil:
    section.add "requestvalidator_id", valid_612538
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612539 = header.getOrDefault("X-Amz-Signature")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-Signature", valid_612539
  var valid_612540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612540 = validateParameter(valid_612540, JString, required = false,
                                 default = nil)
  if valid_612540 != nil:
    section.add "X-Amz-Content-Sha256", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-Date")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-Date", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-Credential")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-Credential", valid_612542
  var valid_612543 = header.getOrDefault("X-Amz-Security-Token")
  valid_612543 = validateParameter(valid_612543, JString, required = false,
                                 default = nil)
  if valid_612543 != nil:
    section.add "X-Amz-Security-Token", valid_612543
  var valid_612544 = header.getOrDefault("X-Amz-Algorithm")
  valid_612544 = validateParameter(valid_612544, JString, required = false,
                                 default = nil)
  if valid_612544 != nil:
    section.add "X-Amz-Algorithm", valid_612544
  var valid_612545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-SignedHeaders", valid_612545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612546: Call_GetRequestValidator_612534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_612546.validator(path, query, header, formData, body)
  let scheme = call_612546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612546.url(scheme.get, call_612546.host, call_612546.base,
                         call_612546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612546, url, valid)

proc call*(call_612547: Call_GetRequestValidator_612534; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  var path_612548 = newJObject()
  add(path_612548, "restapi_id", newJString(restapiId))
  add(path_612548, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_612547.call(path_612548, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_612534(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_612535, base: "/",
    url: url_GetRequestValidator_612536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_612564 = ref object of OpenApiRestCall_610642
proc url_UpdateRequestValidator_612566(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRequestValidator_612565(path: JsonNode; query: JsonNode;
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
  var valid_612567 = path.getOrDefault("restapi_id")
  valid_612567 = validateParameter(valid_612567, JString, required = true,
                                 default = nil)
  if valid_612567 != nil:
    section.add "restapi_id", valid_612567
  var valid_612568 = path.getOrDefault("requestvalidator_id")
  valid_612568 = validateParameter(valid_612568, JString, required = true,
                                 default = nil)
  if valid_612568 != nil:
    section.add "requestvalidator_id", valid_612568
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612569 = header.getOrDefault("X-Amz-Signature")
  valid_612569 = validateParameter(valid_612569, JString, required = false,
                                 default = nil)
  if valid_612569 != nil:
    section.add "X-Amz-Signature", valid_612569
  var valid_612570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612570 = validateParameter(valid_612570, JString, required = false,
                                 default = nil)
  if valid_612570 != nil:
    section.add "X-Amz-Content-Sha256", valid_612570
  var valid_612571 = header.getOrDefault("X-Amz-Date")
  valid_612571 = validateParameter(valid_612571, JString, required = false,
                                 default = nil)
  if valid_612571 != nil:
    section.add "X-Amz-Date", valid_612571
  var valid_612572 = header.getOrDefault("X-Amz-Credential")
  valid_612572 = validateParameter(valid_612572, JString, required = false,
                                 default = nil)
  if valid_612572 != nil:
    section.add "X-Amz-Credential", valid_612572
  var valid_612573 = header.getOrDefault("X-Amz-Security-Token")
  valid_612573 = validateParameter(valid_612573, JString, required = false,
                                 default = nil)
  if valid_612573 != nil:
    section.add "X-Amz-Security-Token", valid_612573
  var valid_612574 = header.getOrDefault("X-Amz-Algorithm")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "X-Amz-Algorithm", valid_612574
  var valid_612575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "X-Amz-SignedHeaders", valid_612575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612577: Call_UpdateRequestValidator_612564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_612577.validator(path, query, header, formData, body)
  let scheme = call_612577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612577.url(scheme.get, call_612577.host, call_612577.base,
                         call_612577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612577, url, valid)

proc call*(call_612578: Call_UpdateRequestValidator_612564; restapiId: string;
          requestvalidatorId: string; body: JsonNode): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  var path_612579 = newJObject()
  var body_612580 = newJObject()
  add(path_612579, "restapi_id", newJString(restapiId))
  add(path_612579, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_612580 = body
  result = call_612578.call(path_612579, nil, nil, nil, body_612580)

var updateRequestValidator* = Call_UpdateRequestValidator_612564(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_612565, base: "/",
    url: url_UpdateRequestValidator_612566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_612549 = ref object of OpenApiRestCall_610642
proc url_DeleteRequestValidator_612551(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRequestValidator_612550(path: JsonNode; query: JsonNode;
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
  var valid_612552 = path.getOrDefault("restapi_id")
  valid_612552 = validateParameter(valid_612552, JString, required = true,
                                 default = nil)
  if valid_612552 != nil:
    section.add "restapi_id", valid_612552
  var valid_612553 = path.getOrDefault("requestvalidator_id")
  valid_612553 = validateParameter(valid_612553, JString, required = true,
                                 default = nil)
  if valid_612553 != nil:
    section.add "requestvalidator_id", valid_612553
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612554 = header.getOrDefault("X-Amz-Signature")
  valid_612554 = validateParameter(valid_612554, JString, required = false,
                                 default = nil)
  if valid_612554 != nil:
    section.add "X-Amz-Signature", valid_612554
  var valid_612555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612555 = validateParameter(valid_612555, JString, required = false,
                                 default = nil)
  if valid_612555 != nil:
    section.add "X-Amz-Content-Sha256", valid_612555
  var valid_612556 = header.getOrDefault("X-Amz-Date")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "X-Amz-Date", valid_612556
  var valid_612557 = header.getOrDefault("X-Amz-Credential")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "X-Amz-Credential", valid_612557
  var valid_612558 = header.getOrDefault("X-Amz-Security-Token")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "X-Amz-Security-Token", valid_612558
  var valid_612559 = header.getOrDefault("X-Amz-Algorithm")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Algorithm", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-SignedHeaders", valid_612560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612561: Call_DeleteRequestValidator_612549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_612561.validator(path, query, header, formData, body)
  let scheme = call_612561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612561.url(scheme.get, call_612561.host, call_612561.base,
                         call_612561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612561, url, valid)

proc call*(call_612562: Call_DeleteRequestValidator_612549; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  var path_612563 = newJObject()
  add(path_612563, "restapi_id", newJString(restapiId))
  add(path_612563, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_612562.call(path_612563, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_612549(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_612550, base: "/",
    url: url_DeleteRequestValidator_612551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_612581 = ref object of OpenApiRestCall_610642
proc url_GetResource_612583(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResource_612582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612584 = path.getOrDefault("restapi_id")
  valid_612584 = validateParameter(valid_612584, JString, required = true,
                                 default = nil)
  if valid_612584 != nil:
    section.add "restapi_id", valid_612584
  var valid_612585 = path.getOrDefault("resource_id")
  valid_612585 = validateParameter(valid_612585, JString, required = true,
                                 default = nil)
  if valid_612585 != nil:
    section.add "resource_id", valid_612585
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_612586 = query.getOrDefault("embed")
  valid_612586 = validateParameter(valid_612586, JArray, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "embed", valid_612586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612587 = header.getOrDefault("X-Amz-Signature")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-Signature", valid_612587
  var valid_612588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612588 = validateParameter(valid_612588, JString, required = false,
                                 default = nil)
  if valid_612588 != nil:
    section.add "X-Amz-Content-Sha256", valid_612588
  var valid_612589 = header.getOrDefault("X-Amz-Date")
  valid_612589 = validateParameter(valid_612589, JString, required = false,
                                 default = nil)
  if valid_612589 != nil:
    section.add "X-Amz-Date", valid_612589
  var valid_612590 = header.getOrDefault("X-Amz-Credential")
  valid_612590 = validateParameter(valid_612590, JString, required = false,
                                 default = nil)
  if valid_612590 != nil:
    section.add "X-Amz-Credential", valid_612590
  var valid_612591 = header.getOrDefault("X-Amz-Security-Token")
  valid_612591 = validateParameter(valid_612591, JString, required = false,
                                 default = nil)
  if valid_612591 != nil:
    section.add "X-Amz-Security-Token", valid_612591
  var valid_612592 = header.getOrDefault("X-Amz-Algorithm")
  valid_612592 = validateParameter(valid_612592, JString, required = false,
                                 default = nil)
  if valid_612592 != nil:
    section.add "X-Amz-Algorithm", valid_612592
  var valid_612593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612593 = validateParameter(valid_612593, JString, required = false,
                                 default = nil)
  if valid_612593 != nil:
    section.add "X-Amz-SignedHeaders", valid_612593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612594: Call_GetResource_612581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_612594.validator(path, query, header, formData, body)
  let scheme = call_612594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612594.url(scheme.get, call_612594.host, call_612594.base,
                         call_612594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612594, url, valid)

proc call*(call_612595: Call_GetResource_612581; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_612596 = newJObject()
  var query_612597 = newJObject()
  add(path_612596, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_612597.add "embed", embed
  add(path_612596, "resource_id", newJString(resourceId))
  result = call_612595.call(path_612596, query_612597, nil, nil, nil)

var getResource* = Call_GetResource_612581(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_612582,
                                        base: "/", url: url_GetResource_612583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_612613 = ref object of OpenApiRestCall_610642
proc url_UpdateResource_612615(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResource_612614(path: JsonNode; query: JsonNode;
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
  var valid_612616 = path.getOrDefault("restapi_id")
  valid_612616 = validateParameter(valid_612616, JString, required = true,
                                 default = nil)
  if valid_612616 != nil:
    section.add "restapi_id", valid_612616
  var valid_612617 = path.getOrDefault("resource_id")
  valid_612617 = validateParameter(valid_612617, JString, required = true,
                                 default = nil)
  if valid_612617 != nil:
    section.add "resource_id", valid_612617
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612618 = header.getOrDefault("X-Amz-Signature")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "X-Amz-Signature", valid_612618
  var valid_612619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "X-Amz-Content-Sha256", valid_612619
  var valid_612620 = header.getOrDefault("X-Amz-Date")
  valid_612620 = validateParameter(valid_612620, JString, required = false,
                                 default = nil)
  if valid_612620 != nil:
    section.add "X-Amz-Date", valid_612620
  var valid_612621 = header.getOrDefault("X-Amz-Credential")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "X-Amz-Credential", valid_612621
  var valid_612622 = header.getOrDefault("X-Amz-Security-Token")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-Security-Token", valid_612622
  var valid_612623 = header.getOrDefault("X-Amz-Algorithm")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "X-Amz-Algorithm", valid_612623
  var valid_612624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612624 = validateParameter(valid_612624, JString, required = false,
                                 default = nil)
  if valid_612624 != nil:
    section.add "X-Amz-SignedHeaders", valid_612624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612626: Call_UpdateResource_612613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_612626.validator(path, query, header, formData, body)
  let scheme = call_612626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612626.url(scheme.get, call_612626.host, call_612626.base,
                         call_612626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612626, url, valid)

proc call*(call_612627: Call_UpdateResource_612613; restapiId: string;
          body: JsonNode; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_612628 = newJObject()
  var body_612629 = newJObject()
  add(path_612628, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612629 = body
  add(path_612628, "resource_id", newJString(resourceId))
  result = call_612627.call(path_612628, nil, nil, nil, body_612629)

var updateResource* = Call_UpdateResource_612613(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_612614, base: "/", url: url_UpdateResource_612615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_612598 = ref object of OpenApiRestCall_610642
proc url_DeleteResource_612600(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResource_612599(path: JsonNode; query: JsonNode;
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
  var valid_612601 = path.getOrDefault("restapi_id")
  valid_612601 = validateParameter(valid_612601, JString, required = true,
                                 default = nil)
  if valid_612601 != nil:
    section.add "restapi_id", valid_612601
  var valid_612602 = path.getOrDefault("resource_id")
  valid_612602 = validateParameter(valid_612602, JString, required = true,
                                 default = nil)
  if valid_612602 != nil:
    section.add "resource_id", valid_612602
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612603 = header.getOrDefault("X-Amz-Signature")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "X-Amz-Signature", valid_612603
  var valid_612604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "X-Amz-Content-Sha256", valid_612604
  var valid_612605 = header.getOrDefault("X-Amz-Date")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "X-Amz-Date", valid_612605
  var valid_612606 = header.getOrDefault("X-Amz-Credential")
  valid_612606 = validateParameter(valid_612606, JString, required = false,
                                 default = nil)
  if valid_612606 != nil:
    section.add "X-Amz-Credential", valid_612606
  var valid_612607 = header.getOrDefault("X-Amz-Security-Token")
  valid_612607 = validateParameter(valid_612607, JString, required = false,
                                 default = nil)
  if valid_612607 != nil:
    section.add "X-Amz-Security-Token", valid_612607
  var valid_612608 = header.getOrDefault("X-Amz-Algorithm")
  valid_612608 = validateParameter(valid_612608, JString, required = false,
                                 default = nil)
  if valid_612608 != nil:
    section.add "X-Amz-Algorithm", valid_612608
  var valid_612609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612609 = validateParameter(valid_612609, JString, required = false,
                                 default = nil)
  if valid_612609 != nil:
    section.add "X-Amz-SignedHeaders", valid_612609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612610: Call_DeleteResource_612598; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_612610.validator(path, query, header, formData, body)
  let scheme = call_612610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612610.url(scheme.get, call_612610.host, call_612610.base,
                         call_612610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612610, url, valid)

proc call*(call_612611: Call_DeleteResource_612598; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_612612 = newJObject()
  add(path_612612, "restapi_id", newJString(restapiId))
  add(path_612612, "resource_id", newJString(resourceId))
  result = call_612611.call(path_612612, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_612598(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_612599, base: "/", url: url_DeleteResource_612600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_612644 = ref object of OpenApiRestCall_610642
proc url_PutRestApi_612646(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutRestApi_612645(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612647 = path.getOrDefault("restapi_id")
  valid_612647 = validateParameter(valid_612647, JString, required = true,
                                 default = nil)
  if valid_612647 != nil:
    section.add "restapi_id", valid_612647
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
  var valid_612648 = query.getOrDefault("failonwarnings")
  valid_612648 = validateParameter(valid_612648, JBool, required = false, default = nil)
  if valid_612648 != nil:
    section.add "failonwarnings", valid_612648
  var valid_612649 = query.getOrDefault("parameters.2.value")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "parameters.2.value", valid_612649
  var valid_612650 = query.getOrDefault("parameters.1.value")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "parameters.1.value", valid_612650
  var valid_612651 = query.getOrDefault("mode")
  valid_612651 = validateParameter(valid_612651, JString, required = false,
                                 default = newJString("merge"))
  if valid_612651 != nil:
    section.add "mode", valid_612651
  var valid_612652 = query.getOrDefault("parameters.1.key")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "parameters.1.key", valid_612652
  var valid_612653 = query.getOrDefault("parameters.2.key")
  valid_612653 = validateParameter(valid_612653, JString, required = false,
                                 default = nil)
  if valid_612653 != nil:
    section.add "parameters.2.key", valid_612653
  var valid_612654 = query.getOrDefault("parameters.0.value")
  valid_612654 = validateParameter(valid_612654, JString, required = false,
                                 default = nil)
  if valid_612654 != nil:
    section.add "parameters.0.value", valid_612654
  var valid_612655 = query.getOrDefault("parameters.0.key")
  valid_612655 = validateParameter(valid_612655, JString, required = false,
                                 default = nil)
  if valid_612655 != nil:
    section.add "parameters.0.key", valid_612655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612656 = header.getOrDefault("X-Amz-Signature")
  valid_612656 = validateParameter(valid_612656, JString, required = false,
                                 default = nil)
  if valid_612656 != nil:
    section.add "X-Amz-Signature", valid_612656
  var valid_612657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612657 = validateParameter(valid_612657, JString, required = false,
                                 default = nil)
  if valid_612657 != nil:
    section.add "X-Amz-Content-Sha256", valid_612657
  var valid_612658 = header.getOrDefault("X-Amz-Date")
  valid_612658 = validateParameter(valid_612658, JString, required = false,
                                 default = nil)
  if valid_612658 != nil:
    section.add "X-Amz-Date", valid_612658
  var valid_612659 = header.getOrDefault("X-Amz-Credential")
  valid_612659 = validateParameter(valid_612659, JString, required = false,
                                 default = nil)
  if valid_612659 != nil:
    section.add "X-Amz-Credential", valid_612659
  var valid_612660 = header.getOrDefault("X-Amz-Security-Token")
  valid_612660 = validateParameter(valid_612660, JString, required = false,
                                 default = nil)
  if valid_612660 != nil:
    section.add "X-Amz-Security-Token", valid_612660
  var valid_612661 = header.getOrDefault("X-Amz-Algorithm")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "X-Amz-Algorithm", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-SignedHeaders", valid_612662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612664: Call_PutRestApi_612644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_612664.validator(path, query, header, formData, body)
  let scheme = call_612664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612664.url(scheme.get, call_612664.host, call_612664.base,
                         call_612664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612664, url, valid)

proc call*(call_612665: Call_PutRestApi_612644; restapiId: string; body: JsonNode;
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
  var path_612666 = newJObject()
  var query_612667 = newJObject()
  var body_612668 = newJObject()
  add(query_612667, "failonwarnings", newJBool(failonwarnings))
  add(query_612667, "parameters.2.value", newJString(parameters2Value))
  add(query_612667, "parameters.1.value", newJString(parameters1Value))
  add(query_612667, "mode", newJString(mode))
  add(query_612667, "parameters.1.key", newJString(parameters1Key))
  add(path_612666, "restapi_id", newJString(restapiId))
  add(query_612667, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_612668 = body
  add(query_612667, "parameters.0.value", newJString(parameters0Value))
  add(query_612667, "parameters.0.key", newJString(parameters0Key))
  result = call_612665.call(path_612666, query_612667, nil, nil, body_612668)

var putRestApi* = Call_PutRestApi_612644(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_612645,
                                      base: "/", url: url_PutRestApi_612646,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_612630 = ref object of OpenApiRestCall_610642
proc url_GetRestApi_612632(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRestApi_612631(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612633 = path.getOrDefault("restapi_id")
  valid_612633 = validateParameter(valid_612633, JString, required = true,
                                 default = nil)
  if valid_612633 != nil:
    section.add "restapi_id", valid_612633
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612634 = header.getOrDefault("X-Amz-Signature")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Signature", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-Content-Sha256", valid_612635
  var valid_612636 = header.getOrDefault("X-Amz-Date")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-Date", valid_612636
  var valid_612637 = header.getOrDefault("X-Amz-Credential")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-Credential", valid_612637
  var valid_612638 = header.getOrDefault("X-Amz-Security-Token")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "X-Amz-Security-Token", valid_612638
  var valid_612639 = header.getOrDefault("X-Amz-Algorithm")
  valid_612639 = validateParameter(valid_612639, JString, required = false,
                                 default = nil)
  if valid_612639 != nil:
    section.add "X-Amz-Algorithm", valid_612639
  var valid_612640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = nil)
  if valid_612640 != nil:
    section.add "X-Amz-SignedHeaders", valid_612640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612641: Call_GetRestApi_612630; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_612641.validator(path, query, header, formData, body)
  let scheme = call_612641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612641.url(scheme.get, call_612641.host, call_612641.base,
                         call_612641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612641, url, valid)

proc call*(call_612642: Call_GetRestApi_612630; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_612643 = newJObject()
  add(path_612643, "restapi_id", newJString(restapiId))
  result = call_612642.call(path_612643, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_612630(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_612631,
                                      base: "/", url: url_GetRestApi_612632,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_612683 = ref object of OpenApiRestCall_610642
proc url_UpdateRestApi_612685(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRestApi_612684(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612686 = path.getOrDefault("restapi_id")
  valid_612686 = validateParameter(valid_612686, JString, required = true,
                                 default = nil)
  if valid_612686 != nil:
    section.add "restapi_id", valid_612686
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612687 = header.getOrDefault("X-Amz-Signature")
  valid_612687 = validateParameter(valid_612687, JString, required = false,
                                 default = nil)
  if valid_612687 != nil:
    section.add "X-Amz-Signature", valid_612687
  var valid_612688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612688 = validateParameter(valid_612688, JString, required = false,
                                 default = nil)
  if valid_612688 != nil:
    section.add "X-Amz-Content-Sha256", valid_612688
  var valid_612689 = header.getOrDefault("X-Amz-Date")
  valid_612689 = validateParameter(valid_612689, JString, required = false,
                                 default = nil)
  if valid_612689 != nil:
    section.add "X-Amz-Date", valid_612689
  var valid_612690 = header.getOrDefault("X-Amz-Credential")
  valid_612690 = validateParameter(valid_612690, JString, required = false,
                                 default = nil)
  if valid_612690 != nil:
    section.add "X-Amz-Credential", valid_612690
  var valid_612691 = header.getOrDefault("X-Amz-Security-Token")
  valid_612691 = validateParameter(valid_612691, JString, required = false,
                                 default = nil)
  if valid_612691 != nil:
    section.add "X-Amz-Security-Token", valid_612691
  var valid_612692 = header.getOrDefault("X-Amz-Algorithm")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-Algorithm", valid_612692
  var valid_612693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-SignedHeaders", valid_612693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612695: Call_UpdateRestApi_612683; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_612695.validator(path, query, header, formData, body)
  let scheme = call_612695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612695.url(scheme.get, call_612695.host, call_612695.base,
                         call_612695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612695, url, valid)

proc call*(call_612696: Call_UpdateRestApi_612683; restapiId: string; body: JsonNode): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_612697 = newJObject()
  var body_612698 = newJObject()
  add(path_612697, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612698 = body
  result = call_612696.call(path_612697, nil, nil, nil, body_612698)

var updateRestApi* = Call_UpdateRestApi_612683(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_612684,
    base: "/", url: url_UpdateRestApi_612685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_612669 = ref object of OpenApiRestCall_610642
proc url_DeleteRestApi_612671(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRestApi_612670(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612672 = path.getOrDefault("restapi_id")
  valid_612672 = validateParameter(valid_612672, JString, required = true,
                                 default = nil)
  if valid_612672 != nil:
    section.add "restapi_id", valid_612672
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612673 = header.getOrDefault("X-Amz-Signature")
  valid_612673 = validateParameter(valid_612673, JString, required = false,
                                 default = nil)
  if valid_612673 != nil:
    section.add "X-Amz-Signature", valid_612673
  var valid_612674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612674 = validateParameter(valid_612674, JString, required = false,
                                 default = nil)
  if valid_612674 != nil:
    section.add "X-Amz-Content-Sha256", valid_612674
  var valid_612675 = header.getOrDefault("X-Amz-Date")
  valid_612675 = validateParameter(valid_612675, JString, required = false,
                                 default = nil)
  if valid_612675 != nil:
    section.add "X-Amz-Date", valid_612675
  var valid_612676 = header.getOrDefault("X-Amz-Credential")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "X-Amz-Credential", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-Security-Token")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-Security-Token", valid_612677
  var valid_612678 = header.getOrDefault("X-Amz-Algorithm")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-Algorithm", valid_612678
  var valid_612679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612679 = validateParameter(valid_612679, JString, required = false,
                                 default = nil)
  if valid_612679 != nil:
    section.add "X-Amz-SignedHeaders", valid_612679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612680: Call_DeleteRestApi_612669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_612680.validator(path, query, header, formData, body)
  let scheme = call_612680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612680.url(scheme.get, call_612680.host, call_612680.base,
                         call_612680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612680, url, valid)

proc call*(call_612681: Call_DeleteRestApi_612669; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_612682 = newJObject()
  add(path_612682, "restapi_id", newJString(restapiId))
  result = call_612681.call(path_612682, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_612669(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_612670,
    base: "/", url: url_DeleteRestApi_612671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_612699 = ref object of OpenApiRestCall_610642
proc url_GetStage_612701(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStage_612700(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612702 = path.getOrDefault("restapi_id")
  valid_612702 = validateParameter(valid_612702, JString, required = true,
                                 default = nil)
  if valid_612702 != nil:
    section.add "restapi_id", valid_612702
  var valid_612703 = path.getOrDefault("stage_name")
  valid_612703 = validateParameter(valid_612703, JString, required = true,
                                 default = nil)
  if valid_612703 != nil:
    section.add "stage_name", valid_612703
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612704 = header.getOrDefault("X-Amz-Signature")
  valid_612704 = validateParameter(valid_612704, JString, required = false,
                                 default = nil)
  if valid_612704 != nil:
    section.add "X-Amz-Signature", valid_612704
  var valid_612705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612705 = validateParameter(valid_612705, JString, required = false,
                                 default = nil)
  if valid_612705 != nil:
    section.add "X-Amz-Content-Sha256", valid_612705
  var valid_612706 = header.getOrDefault("X-Amz-Date")
  valid_612706 = validateParameter(valid_612706, JString, required = false,
                                 default = nil)
  if valid_612706 != nil:
    section.add "X-Amz-Date", valid_612706
  var valid_612707 = header.getOrDefault("X-Amz-Credential")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "X-Amz-Credential", valid_612707
  var valid_612708 = header.getOrDefault("X-Amz-Security-Token")
  valid_612708 = validateParameter(valid_612708, JString, required = false,
                                 default = nil)
  if valid_612708 != nil:
    section.add "X-Amz-Security-Token", valid_612708
  var valid_612709 = header.getOrDefault("X-Amz-Algorithm")
  valid_612709 = validateParameter(valid_612709, JString, required = false,
                                 default = nil)
  if valid_612709 != nil:
    section.add "X-Amz-Algorithm", valid_612709
  var valid_612710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "X-Amz-SignedHeaders", valid_612710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612711: Call_GetStage_612699; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_612711.validator(path, query, header, formData, body)
  let scheme = call_612711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612711.url(scheme.get, call_612711.host, call_612711.base,
                         call_612711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612711, url, valid)

proc call*(call_612712: Call_GetStage_612699; restapiId: string; stageName: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  var path_612713 = newJObject()
  add(path_612713, "restapi_id", newJString(restapiId))
  add(path_612713, "stage_name", newJString(stageName))
  result = call_612712.call(path_612713, nil, nil, nil, nil)

var getStage* = Call_GetStage_612699(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_612700, base: "/",
                                  url: url_GetStage_612701,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_612729 = ref object of OpenApiRestCall_610642
proc url_UpdateStage_612731(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStage_612730(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612732 = path.getOrDefault("restapi_id")
  valid_612732 = validateParameter(valid_612732, JString, required = true,
                                 default = nil)
  if valid_612732 != nil:
    section.add "restapi_id", valid_612732
  var valid_612733 = path.getOrDefault("stage_name")
  valid_612733 = validateParameter(valid_612733, JString, required = true,
                                 default = nil)
  if valid_612733 != nil:
    section.add "stage_name", valid_612733
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612734 = header.getOrDefault("X-Amz-Signature")
  valid_612734 = validateParameter(valid_612734, JString, required = false,
                                 default = nil)
  if valid_612734 != nil:
    section.add "X-Amz-Signature", valid_612734
  var valid_612735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612735 = validateParameter(valid_612735, JString, required = false,
                                 default = nil)
  if valid_612735 != nil:
    section.add "X-Amz-Content-Sha256", valid_612735
  var valid_612736 = header.getOrDefault("X-Amz-Date")
  valid_612736 = validateParameter(valid_612736, JString, required = false,
                                 default = nil)
  if valid_612736 != nil:
    section.add "X-Amz-Date", valid_612736
  var valid_612737 = header.getOrDefault("X-Amz-Credential")
  valid_612737 = validateParameter(valid_612737, JString, required = false,
                                 default = nil)
  if valid_612737 != nil:
    section.add "X-Amz-Credential", valid_612737
  var valid_612738 = header.getOrDefault("X-Amz-Security-Token")
  valid_612738 = validateParameter(valid_612738, JString, required = false,
                                 default = nil)
  if valid_612738 != nil:
    section.add "X-Amz-Security-Token", valid_612738
  var valid_612739 = header.getOrDefault("X-Amz-Algorithm")
  valid_612739 = validateParameter(valid_612739, JString, required = false,
                                 default = nil)
  if valid_612739 != nil:
    section.add "X-Amz-Algorithm", valid_612739
  var valid_612740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612740 = validateParameter(valid_612740, JString, required = false,
                                 default = nil)
  if valid_612740 != nil:
    section.add "X-Amz-SignedHeaders", valid_612740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612742: Call_UpdateStage_612729; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_612742.validator(path, query, header, formData, body)
  let scheme = call_612742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612742.url(scheme.get, call_612742.host, call_612742.base,
                         call_612742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612742, url, valid)

proc call*(call_612743: Call_UpdateStage_612729; restapiId: string; body: JsonNode;
          stageName: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  var path_612744 = newJObject()
  var body_612745 = newJObject()
  add(path_612744, "restapi_id", newJString(restapiId))
  if body != nil:
    body_612745 = body
  add(path_612744, "stage_name", newJString(stageName))
  result = call_612743.call(path_612744, nil, nil, nil, body_612745)

var updateStage* = Call_UpdateStage_612729(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_612730,
                                        base: "/", url: url_UpdateStage_612731,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_612714 = ref object of OpenApiRestCall_610642
proc url_DeleteStage_612716(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStage_612715(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612717 = path.getOrDefault("restapi_id")
  valid_612717 = validateParameter(valid_612717, JString, required = true,
                                 default = nil)
  if valid_612717 != nil:
    section.add "restapi_id", valid_612717
  var valid_612718 = path.getOrDefault("stage_name")
  valid_612718 = validateParameter(valid_612718, JString, required = true,
                                 default = nil)
  if valid_612718 != nil:
    section.add "stage_name", valid_612718
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612719 = header.getOrDefault("X-Amz-Signature")
  valid_612719 = validateParameter(valid_612719, JString, required = false,
                                 default = nil)
  if valid_612719 != nil:
    section.add "X-Amz-Signature", valid_612719
  var valid_612720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612720 = validateParameter(valid_612720, JString, required = false,
                                 default = nil)
  if valid_612720 != nil:
    section.add "X-Amz-Content-Sha256", valid_612720
  var valid_612721 = header.getOrDefault("X-Amz-Date")
  valid_612721 = validateParameter(valid_612721, JString, required = false,
                                 default = nil)
  if valid_612721 != nil:
    section.add "X-Amz-Date", valid_612721
  var valid_612722 = header.getOrDefault("X-Amz-Credential")
  valid_612722 = validateParameter(valid_612722, JString, required = false,
                                 default = nil)
  if valid_612722 != nil:
    section.add "X-Amz-Credential", valid_612722
  var valid_612723 = header.getOrDefault("X-Amz-Security-Token")
  valid_612723 = validateParameter(valid_612723, JString, required = false,
                                 default = nil)
  if valid_612723 != nil:
    section.add "X-Amz-Security-Token", valid_612723
  var valid_612724 = header.getOrDefault("X-Amz-Algorithm")
  valid_612724 = validateParameter(valid_612724, JString, required = false,
                                 default = nil)
  if valid_612724 != nil:
    section.add "X-Amz-Algorithm", valid_612724
  var valid_612725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612725 = validateParameter(valid_612725, JString, required = false,
                                 default = nil)
  if valid_612725 != nil:
    section.add "X-Amz-SignedHeaders", valid_612725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612726: Call_DeleteStage_612714; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_612726.validator(path, query, header, formData, body)
  let scheme = call_612726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612726.url(scheme.get, call_612726.host, call_612726.base,
                         call_612726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612726, url, valid)

proc call*(call_612727: Call_DeleteStage_612714; restapiId: string; stageName: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  var path_612728 = newJObject()
  add(path_612728, "restapi_id", newJString(restapiId))
  add(path_612728, "stage_name", newJString(stageName))
  result = call_612727.call(path_612728, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_612714(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_612715,
                                        base: "/", url: url_DeleteStage_612716,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_612746 = ref object of OpenApiRestCall_610642
proc url_GetUsagePlan_612748(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsagePlan_612747(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612749 = path.getOrDefault("usageplanId")
  valid_612749 = validateParameter(valid_612749, JString, required = true,
                                 default = nil)
  if valid_612749 != nil:
    section.add "usageplanId", valid_612749
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612750 = header.getOrDefault("X-Amz-Signature")
  valid_612750 = validateParameter(valid_612750, JString, required = false,
                                 default = nil)
  if valid_612750 != nil:
    section.add "X-Amz-Signature", valid_612750
  var valid_612751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612751 = validateParameter(valid_612751, JString, required = false,
                                 default = nil)
  if valid_612751 != nil:
    section.add "X-Amz-Content-Sha256", valid_612751
  var valid_612752 = header.getOrDefault("X-Amz-Date")
  valid_612752 = validateParameter(valid_612752, JString, required = false,
                                 default = nil)
  if valid_612752 != nil:
    section.add "X-Amz-Date", valid_612752
  var valid_612753 = header.getOrDefault("X-Amz-Credential")
  valid_612753 = validateParameter(valid_612753, JString, required = false,
                                 default = nil)
  if valid_612753 != nil:
    section.add "X-Amz-Credential", valid_612753
  var valid_612754 = header.getOrDefault("X-Amz-Security-Token")
  valid_612754 = validateParameter(valid_612754, JString, required = false,
                                 default = nil)
  if valid_612754 != nil:
    section.add "X-Amz-Security-Token", valid_612754
  var valid_612755 = header.getOrDefault("X-Amz-Algorithm")
  valid_612755 = validateParameter(valid_612755, JString, required = false,
                                 default = nil)
  if valid_612755 != nil:
    section.add "X-Amz-Algorithm", valid_612755
  var valid_612756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612756 = validateParameter(valid_612756, JString, required = false,
                                 default = nil)
  if valid_612756 != nil:
    section.add "X-Amz-SignedHeaders", valid_612756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612757: Call_GetUsagePlan_612746; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_612757.validator(path, query, header, formData, body)
  let scheme = call_612757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612757.url(scheme.get, call_612757.host, call_612757.base,
                         call_612757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612757, url, valid)

proc call*(call_612758: Call_GetUsagePlan_612746; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_612759 = newJObject()
  add(path_612759, "usageplanId", newJString(usageplanId))
  result = call_612758.call(path_612759, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_612746(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_612747,
    base: "/", url: url_GetUsagePlan_612748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_612774 = ref object of OpenApiRestCall_610642
proc url_UpdateUsagePlan_612776(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUsagePlan_612775(path: JsonNode; query: JsonNode;
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
  var valid_612777 = path.getOrDefault("usageplanId")
  valid_612777 = validateParameter(valid_612777, JString, required = true,
                                 default = nil)
  if valid_612777 != nil:
    section.add "usageplanId", valid_612777
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612778 = header.getOrDefault("X-Amz-Signature")
  valid_612778 = validateParameter(valid_612778, JString, required = false,
                                 default = nil)
  if valid_612778 != nil:
    section.add "X-Amz-Signature", valid_612778
  var valid_612779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612779 = validateParameter(valid_612779, JString, required = false,
                                 default = nil)
  if valid_612779 != nil:
    section.add "X-Amz-Content-Sha256", valid_612779
  var valid_612780 = header.getOrDefault("X-Amz-Date")
  valid_612780 = validateParameter(valid_612780, JString, required = false,
                                 default = nil)
  if valid_612780 != nil:
    section.add "X-Amz-Date", valid_612780
  var valid_612781 = header.getOrDefault("X-Amz-Credential")
  valid_612781 = validateParameter(valid_612781, JString, required = false,
                                 default = nil)
  if valid_612781 != nil:
    section.add "X-Amz-Credential", valid_612781
  var valid_612782 = header.getOrDefault("X-Amz-Security-Token")
  valid_612782 = validateParameter(valid_612782, JString, required = false,
                                 default = nil)
  if valid_612782 != nil:
    section.add "X-Amz-Security-Token", valid_612782
  var valid_612783 = header.getOrDefault("X-Amz-Algorithm")
  valid_612783 = validateParameter(valid_612783, JString, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "X-Amz-Algorithm", valid_612783
  var valid_612784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612784 = validateParameter(valid_612784, JString, required = false,
                                 default = nil)
  if valid_612784 != nil:
    section.add "X-Amz-SignedHeaders", valid_612784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612786: Call_UpdateUsagePlan_612774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_612786.validator(path, query, header, formData, body)
  let scheme = call_612786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612786.url(scheme.get, call_612786.host, call_612786.base,
                         call_612786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612786, url, valid)

proc call*(call_612787: Call_UpdateUsagePlan_612774; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_612788 = newJObject()
  var body_612789 = newJObject()
  add(path_612788, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_612789 = body
  result = call_612787.call(path_612788, nil, nil, nil, body_612789)

var updateUsagePlan* = Call_UpdateUsagePlan_612774(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_612775,
    base: "/", url: url_UpdateUsagePlan_612776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_612760 = ref object of OpenApiRestCall_610642
proc url_DeleteUsagePlan_612762(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUsagePlan_612761(path: JsonNode; query: JsonNode;
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
  var valid_612763 = path.getOrDefault("usageplanId")
  valid_612763 = validateParameter(valid_612763, JString, required = true,
                                 default = nil)
  if valid_612763 != nil:
    section.add "usageplanId", valid_612763
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612764 = header.getOrDefault("X-Amz-Signature")
  valid_612764 = validateParameter(valid_612764, JString, required = false,
                                 default = nil)
  if valid_612764 != nil:
    section.add "X-Amz-Signature", valid_612764
  var valid_612765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612765 = validateParameter(valid_612765, JString, required = false,
                                 default = nil)
  if valid_612765 != nil:
    section.add "X-Amz-Content-Sha256", valid_612765
  var valid_612766 = header.getOrDefault("X-Amz-Date")
  valid_612766 = validateParameter(valid_612766, JString, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "X-Amz-Date", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-Credential")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-Credential", valid_612767
  var valid_612768 = header.getOrDefault("X-Amz-Security-Token")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "X-Amz-Security-Token", valid_612768
  var valid_612769 = header.getOrDefault("X-Amz-Algorithm")
  valid_612769 = validateParameter(valid_612769, JString, required = false,
                                 default = nil)
  if valid_612769 != nil:
    section.add "X-Amz-Algorithm", valid_612769
  var valid_612770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612770 = validateParameter(valid_612770, JString, required = false,
                                 default = nil)
  if valid_612770 != nil:
    section.add "X-Amz-SignedHeaders", valid_612770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612771: Call_DeleteUsagePlan_612760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_612771.validator(path, query, header, formData, body)
  let scheme = call_612771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612771.url(scheme.get, call_612771.host, call_612771.base,
                         call_612771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612771, url, valid)

proc call*(call_612772: Call_DeleteUsagePlan_612760; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_612773 = newJObject()
  add(path_612773, "usageplanId", newJString(usageplanId))
  result = call_612772.call(path_612773, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_612760(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_612761,
    base: "/", url: url_DeleteUsagePlan_612762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_612790 = ref object of OpenApiRestCall_610642
proc url_GetUsagePlanKey_612792(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsagePlanKey_612791(path: JsonNode; query: JsonNode;
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
  var valid_612793 = path.getOrDefault("usageplanId")
  valid_612793 = validateParameter(valid_612793, JString, required = true,
                                 default = nil)
  if valid_612793 != nil:
    section.add "usageplanId", valid_612793
  var valid_612794 = path.getOrDefault("keyId")
  valid_612794 = validateParameter(valid_612794, JString, required = true,
                                 default = nil)
  if valid_612794 != nil:
    section.add "keyId", valid_612794
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612795 = header.getOrDefault("X-Amz-Signature")
  valid_612795 = validateParameter(valid_612795, JString, required = false,
                                 default = nil)
  if valid_612795 != nil:
    section.add "X-Amz-Signature", valid_612795
  var valid_612796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612796 = validateParameter(valid_612796, JString, required = false,
                                 default = nil)
  if valid_612796 != nil:
    section.add "X-Amz-Content-Sha256", valid_612796
  var valid_612797 = header.getOrDefault("X-Amz-Date")
  valid_612797 = validateParameter(valid_612797, JString, required = false,
                                 default = nil)
  if valid_612797 != nil:
    section.add "X-Amz-Date", valid_612797
  var valid_612798 = header.getOrDefault("X-Amz-Credential")
  valid_612798 = validateParameter(valid_612798, JString, required = false,
                                 default = nil)
  if valid_612798 != nil:
    section.add "X-Amz-Credential", valid_612798
  var valid_612799 = header.getOrDefault("X-Amz-Security-Token")
  valid_612799 = validateParameter(valid_612799, JString, required = false,
                                 default = nil)
  if valid_612799 != nil:
    section.add "X-Amz-Security-Token", valid_612799
  var valid_612800 = header.getOrDefault("X-Amz-Algorithm")
  valid_612800 = validateParameter(valid_612800, JString, required = false,
                                 default = nil)
  if valid_612800 != nil:
    section.add "X-Amz-Algorithm", valid_612800
  var valid_612801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612801 = validateParameter(valid_612801, JString, required = false,
                                 default = nil)
  if valid_612801 != nil:
    section.add "X-Amz-SignedHeaders", valid_612801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612802: Call_GetUsagePlanKey_612790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_612802.validator(path, query, header, formData, body)
  let scheme = call_612802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612802.url(scheme.get, call_612802.host, call_612802.base,
                         call_612802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612802, url, valid)

proc call*(call_612803: Call_GetUsagePlanKey_612790; usageplanId: string;
          keyId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_612804 = newJObject()
  add(path_612804, "usageplanId", newJString(usageplanId))
  add(path_612804, "keyId", newJString(keyId))
  result = call_612803.call(path_612804, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_612790(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_612791, base: "/", url: url_GetUsagePlanKey_612792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_612805 = ref object of OpenApiRestCall_610642
proc url_DeleteUsagePlanKey_612807(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUsagePlanKey_612806(path: JsonNode; query: JsonNode;
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
  var valid_612808 = path.getOrDefault("usageplanId")
  valid_612808 = validateParameter(valid_612808, JString, required = true,
                                 default = nil)
  if valid_612808 != nil:
    section.add "usageplanId", valid_612808
  var valid_612809 = path.getOrDefault("keyId")
  valid_612809 = validateParameter(valid_612809, JString, required = true,
                                 default = nil)
  if valid_612809 != nil:
    section.add "keyId", valid_612809
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612810 = header.getOrDefault("X-Amz-Signature")
  valid_612810 = validateParameter(valid_612810, JString, required = false,
                                 default = nil)
  if valid_612810 != nil:
    section.add "X-Amz-Signature", valid_612810
  var valid_612811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612811 = validateParameter(valid_612811, JString, required = false,
                                 default = nil)
  if valid_612811 != nil:
    section.add "X-Amz-Content-Sha256", valid_612811
  var valid_612812 = header.getOrDefault("X-Amz-Date")
  valid_612812 = validateParameter(valid_612812, JString, required = false,
                                 default = nil)
  if valid_612812 != nil:
    section.add "X-Amz-Date", valid_612812
  var valid_612813 = header.getOrDefault("X-Amz-Credential")
  valid_612813 = validateParameter(valid_612813, JString, required = false,
                                 default = nil)
  if valid_612813 != nil:
    section.add "X-Amz-Credential", valid_612813
  var valid_612814 = header.getOrDefault("X-Amz-Security-Token")
  valid_612814 = validateParameter(valid_612814, JString, required = false,
                                 default = nil)
  if valid_612814 != nil:
    section.add "X-Amz-Security-Token", valid_612814
  var valid_612815 = header.getOrDefault("X-Amz-Algorithm")
  valid_612815 = validateParameter(valid_612815, JString, required = false,
                                 default = nil)
  if valid_612815 != nil:
    section.add "X-Amz-Algorithm", valid_612815
  var valid_612816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612816 = validateParameter(valid_612816, JString, required = false,
                                 default = nil)
  if valid_612816 != nil:
    section.add "X-Amz-SignedHeaders", valid_612816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612817: Call_DeleteUsagePlanKey_612805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_612817.validator(path, query, header, formData, body)
  let scheme = call_612817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612817.url(scheme.get, call_612817.host, call_612817.base,
                         call_612817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612817, url, valid)

proc call*(call_612818: Call_DeleteUsagePlanKey_612805; usageplanId: string;
          keyId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  var path_612819 = newJObject()
  add(path_612819, "usageplanId", newJString(usageplanId))
  add(path_612819, "keyId", newJString(keyId))
  result = call_612818.call(path_612819, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_612805(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_612806, base: "/",
    url: url_DeleteUsagePlanKey_612807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_612820 = ref object of OpenApiRestCall_610642
proc url_GetVpcLink_612822(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVpcLink_612821(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612823 = path.getOrDefault("vpclink_id")
  valid_612823 = validateParameter(valid_612823, JString, required = true,
                                 default = nil)
  if valid_612823 != nil:
    section.add "vpclink_id", valid_612823
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612824 = header.getOrDefault("X-Amz-Signature")
  valid_612824 = validateParameter(valid_612824, JString, required = false,
                                 default = nil)
  if valid_612824 != nil:
    section.add "X-Amz-Signature", valid_612824
  var valid_612825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612825 = validateParameter(valid_612825, JString, required = false,
                                 default = nil)
  if valid_612825 != nil:
    section.add "X-Amz-Content-Sha256", valid_612825
  var valid_612826 = header.getOrDefault("X-Amz-Date")
  valid_612826 = validateParameter(valid_612826, JString, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "X-Amz-Date", valid_612826
  var valid_612827 = header.getOrDefault("X-Amz-Credential")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "X-Amz-Credential", valid_612827
  var valid_612828 = header.getOrDefault("X-Amz-Security-Token")
  valid_612828 = validateParameter(valid_612828, JString, required = false,
                                 default = nil)
  if valid_612828 != nil:
    section.add "X-Amz-Security-Token", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-Algorithm")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-Algorithm", valid_612829
  var valid_612830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612830 = validateParameter(valid_612830, JString, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "X-Amz-SignedHeaders", valid_612830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612831: Call_GetVpcLink_612820; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_612831.validator(path, query, header, formData, body)
  let scheme = call_612831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612831.url(scheme.get, call_612831.host, call_612831.base,
                         call_612831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612831, url, valid)

proc call*(call_612832: Call_GetVpcLink_612820; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_612833 = newJObject()
  add(path_612833, "vpclink_id", newJString(vpclinkId))
  result = call_612832.call(path_612833, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_612820(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_612821,
                                      base: "/", url: url_GetVpcLink_612822,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_612848 = ref object of OpenApiRestCall_610642
proc url_UpdateVpcLink_612850(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVpcLink_612849(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612851 = path.getOrDefault("vpclink_id")
  valid_612851 = validateParameter(valid_612851, JString, required = true,
                                 default = nil)
  if valid_612851 != nil:
    section.add "vpclink_id", valid_612851
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612852 = header.getOrDefault("X-Amz-Signature")
  valid_612852 = validateParameter(valid_612852, JString, required = false,
                                 default = nil)
  if valid_612852 != nil:
    section.add "X-Amz-Signature", valid_612852
  var valid_612853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612853 = validateParameter(valid_612853, JString, required = false,
                                 default = nil)
  if valid_612853 != nil:
    section.add "X-Amz-Content-Sha256", valid_612853
  var valid_612854 = header.getOrDefault("X-Amz-Date")
  valid_612854 = validateParameter(valid_612854, JString, required = false,
                                 default = nil)
  if valid_612854 != nil:
    section.add "X-Amz-Date", valid_612854
  var valid_612855 = header.getOrDefault("X-Amz-Credential")
  valid_612855 = validateParameter(valid_612855, JString, required = false,
                                 default = nil)
  if valid_612855 != nil:
    section.add "X-Amz-Credential", valid_612855
  var valid_612856 = header.getOrDefault("X-Amz-Security-Token")
  valid_612856 = validateParameter(valid_612856, JString, required = false,
                                 default = nil)
  if valid_612856 != nil:
    section.add "X-Amz-Security-Token", valid_612856
  var valid_612857 = header.getOrDefault("X-Amz-Algorithm")
  valid_612857 = validateParameter(valid_612857, JString, required = false,
                                 default = nil)
  if valid_612857 != nil:
    section.add "X-Amz-Algorithm", valid_612857
  var valid_612858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612858 = validateParameter(valid_612858, JString, required = false,
                                 default = nil)
  if valid_612858 != nil:
    section.add "X-Amz-SignedHeaders", valid_612858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612860: Call_UpdateVpcLink_612848; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_612860.validator(path, query, header, formData, body)
  let scheme = call_612860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612860.url(scheme.get, call_612860.host, call_612860.base,
                         call_612860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612860, url, valid)

proc call*(call_612861: Call_UpdateVpcLink_612848; vpclinkId: string; body: JsonNode): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  ##   body: JObject (required)
  var path_612862 = newJObject()
  var body_612863 = newJObject()
  add(path_612862, "vpclink_id", newJString(vpclinkId))
  if body != nil:
    body_612863 = body
  result = call_612861.call(path_612862, nil, nil, nil, body_612863)

var updateVpcLink* = Call_UpdateVpcLink_612848(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_612849,
    base: "/", url: url_UpdateVpcLink_612850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_612834 = ref object of OpenApiRestCall_610642
proc url_DeleteVpcLink_612836(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVpcLink_612835(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612837 = path.getOrDefault("vpclink_id")
  valid_612837 = validateParameter(valid_612837, JString, required = true,
                                 default = nil)
  if valid_612837 != nil:
    section.add "vpclink_id", valid_612837
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612838 = header.getOrDefault("X-Amz-Signature")
  valid_612838 = validateParameter(valid_612838, JString, required = false,
                                 default = nil)
  if valid_612838 != nil:
    section.add "X-Amz-Signature", valid_612838
  var valid_612839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612839 = validateParameter(valid_612839, JString, required = false,
                                 default = nil)
  if valid_612839 != nil:
    section.add "X-Amz-Content-Sha256", valid_612839
  var valid_612840 = header.getOrDefault("X-Amz-Date")
  valid_612840 = validateParameter(valid_612840, JString, required = false,
                                 default = nil)
  if valid_612840 != nil:
    section.add "X-Amz-Date", valid_612840
  var valid_612841 = header.getOrDefault("X-Amz-Credential")
  valid_612841 = validateParameter(valid_612841, JString, required = false,
                                 default = nil)
  if valid_612841 != nil:
    section.add "X-Amz-Credential", valid_612841
  var valid_612842 = header.getOrDefault("X-Amz-Security-Token")
  valid_612842 = validateParameter(valid_612842, JString, required = false,
                                 default = nil)
  if valid_612842 != nil:
    section.add "X-Amz-Security-Token", valid_612842
  var valid_612843 = header.getOrDefault("X-Amz-Algorithm")
  valid_612843 = validateParameter(valid_612843, JString, required = false,
                                 default = nil)
  if valid_612843 != nil:
    section.add "X-Amz-Algorithm", valid_612843
  var valid_612844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "X-Amz-SignedHeaders", valid_612844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612845: Call_DeleteVpcLink_612834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_612845.validator(path, query, header, formData, body)
  let scheme = call_612845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612845.url(scheme.get, call_612845.host, call_612845.base,
                         call_612845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612845, url, valid)

proc call*(call_612846: Call_DeleteVpcLink_612834; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_612847 = newJObject()
  add(path_612847, "vpclink_id", newJString(vpclinkId))
  result = call_612846.call(path_612847, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_612834(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_612835,
    base: "/", url: url_DeleteVpcLink_612836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_612864 = ref object of OpenApiRestCall_610642
proc url_FlushStageAuthorizersCache_612866(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FlushStageAuthorizersCache_612865(path: JsonNode; query: JsonNode;
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
  var valid_612867 = path.getOrDefault("restapi_id")
  valid_612867 = validateParameter(valid_612867, JString, required = true,
                                 default = nil)
  if valid_612867 != nil:
    section.add "restapi_id", valid_612867
  var valid_612868 = path.getOrDefault("stage_name")
  valid_612868 = validateParameter(valid_612868, JString, required = true,
                                 default = nil)
  if valid_612868 != nil:
    section.add "stage_name", valid_612868
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612869 = header.getOrDefault("X-Amz-Signature")
  valid_612869 = validateParameter(valid_612869, JString, required = false,
                                 default = nil)
  if valid_612869 != nil:
    section.add "X-Amz-Signature", valid_612869
  var valid_612870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612870 = validateParameter(valid_612870, JString, required = false,
                                 default = nil)
  if valid_612870 != nil:
    section.add "X-Amz-Content-Sha256", valid_612870
  var valid_612871 = header.getOrDefault("X-Amz-Date")
  valid_612871 = validateParameter(valid_612871, JString, required = false,
                                 default = nil)
  if valid_612871 != nil:
    section.add "X-Amz-Date", valid_612871
  var valid_612872 = header.getOrDefault("X-Amz-Credential")
  valid_612872 = validateParameter(valid_612872, JString, required = false,
                                 default = nil)
  if valid_612872 != nil:
    section.add "X-Amz-Credential", valid_612872
  var valid_612873 = header.getOrDefault("X-Amz-Security-Token")
  valid_612873 = validateParameter(valid_612873, JString, required = false,
                                 default = nil)
  if valid_612873 != nil:
    section.add "X-Amz-Security-Token", valid_612873
  var valid_612874 = header.getOrDefault("X-Amz-Algorithm")
  valid_612874 = validateParameter(valid_612874, JString, required = false,
                                 default = nil)
  if valid_612874 != nil:
    section.add "X-Amz-Algorithm", valid_612874
  var valid_612875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612875 = validateParameter(valid_612875, JString, required = false,
                                 default = nil)
  if valid_612875 != nil:
    section.add "X-Amz-SignedHeaders", valid_612875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612876: Call_FlushStageAuthorizersCache_612864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_612876.validator(path, query, header, formData, body)
  let scheme = call_612876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612876.url(scheme.get, call_612876.host, call_612876.base,
                         call_612876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612876, url, valid)

proc call*(call_612877: Call_FlushStageAuthorizersCache_612864; restapiId: string;
          stageName: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  var path_612878 = newJObject()
  add(path_612878, "restapi_id", newJString(restapiId))
  add(path_612878, "stage_name", newJString(stageName))
  result = call_612877.call(path_612878, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_612864(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_612865, base: "/",
    url: url_FlushStageAuthorizersCache_612866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_612879 = ref object of OpenApiRestCall_610642
proc url_FlushStageCache_612881(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FlushStageCache_612880(path: JsonNode; query: JsonNode;
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
  var valid_612882 = path.getOrDefault("restapi_id")
  valid_612882 = validateParameter(valid_612882, JString, required = true,
                                 default = nil)
  if valid_612882 != nil:
    section.add "restapi_id", valid_612882
  var valid_612883 = path.getOrDefault("stage_name")
  valid_612883 = validateParameter(valid_612883, JString, required = true,
                                 default = nil)
  if valid_612883 != nil:
    section.add "stage_name", valid_612883
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612884 = header.getOrDefault("X-Amz-Signature")
  valid_612884 = validateParameter(valid_612884, JString, required = false,
                                 default = nil)
  if valid_612884 != nil:
    section.add "X-Amz-Signature", valid_612884
  var valid_612885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612885 = validateParameter(valid_612885, JString, required = false,
                                 default = nil)
  if valid_612885 != nil:
    section.add "X-Amz-Content-Sha256", valid_612885
  var valid_612886 = header.getOrDefault("X-Amz-Date")
  valid_612886 = validateParameter(valid_612886, JString, required = false,
                                 default = nil)
  if valid_612886 != nil:
    section.add "X-Amz-Date", valid_612886
  var valid_612887 = header.getOrDefault("X-Amz-Credential")
  valid_612887 = validateParameter(valid_612887, JString, required = false,
                                 default = nil)
  if valid_612887 != nil:
    section.add "X-Amz-Credential", valid_612887
  var valid_612888 = header.getOrDefault("X-Amz-Security-Token")
  valid_612888 = validateParameter(valid_612888, JString, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "X-Amz-Security-Token", valid_612888
  var valid_612889 = header.getOrDefault("X-Amz-Algorithm")
  valid_612889 = validateParameter(valid_612889, JString, required = false,
                                 default = nil)
  if valid_612889 != nil:
    section.add "X-Amz-Algorithm", valid_612889
  var valid_612890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612890 = validateParameter(valid_612890, JString, required = false,
                                 default = nil)
  if valid_612890 != nil:
    section.add "X-Amz-SignedHeaders", valid_612890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612891: Call_FlushStageCache_612879; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_612891.validator(path, query, header, formData, body)
  let scheme = call_612891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612891.url(scheme.get, call_612891.host, call_612891.base,
                         call_612891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612891, url, valid)

proc call*(call_612892: Call_FlushStageCache_612879; restapiId: string;
          stageName: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  var path_612893 = newJObject()
  add(path_612893, "restapi_id", newJString(restapiId))
  add(path_612893, "stage_name", newJString(stageName))
  result = call_612892.call(path_612893, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_612879(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_612880, base: "/", url: url_FlushStageCache_612881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_612909 = ref object of OpenApiRestCall_610642
proc url_GenerateClientCertificate_612911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateClientCertificate_612910(path: JsonNode; query: JsonNode;
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
  var valid_612912 = header.getOrDefault("X-Amz-Signature")
  valid_612912 = validateParameter(valid_612912, JString, required = false,
                                 default = nil)
  if valid_612912 != nil:
    section.add "X-Amz-Signature", valid_612912
  var valid_612913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612913 = validateParameter(valid_612913, JString, required = false,
                                 default = nil)
  if valid_612913 != nil:
    section.add "X-Amz-Content-Sha256", valid_612913
  var valid_612914 = header.getOrDefault("X-Amz-Date")
  valid_612914 = validateParameter(valid_612914, JString, required = false,
                                 default = nil)
  if valid_612914 != nil:
    section.add "X-Amz-Date", valid_612914
  var valid_612915 = header.getOrDefault("X-Amz-Credential")
  valid_612915 = validateParameter(valid_612915, JString, required = false,
                                 default = nil)
  if valid_612915 != nil:
    section.add "X-Amz-Credential", valid_612915
  var valid_612916 = header.getOrDefault("X-Amz-Security-Token")
  valid_612916 = validateParameter(valid_612916, JString, required = false,
                                 default = nil)
  if valid_612916 != nil:
    section.add "X-Amz-Security-Token", valid_612916
  var valid_612917 = header.getOrDefault("X-Amz-Algorithm")
  valid_612917 = validateParameter(valid_612917, JString, required = false,
                                 default = nil)
  if valid_612917 != nil:
    section.add "X-Amz-Algorithm", valid_612917
  var valid_612918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612918 = validateParameter(valid_612918, JString, required = false,
                                 default = nil)
  if valid_612918 != nil:
    section.add "X-Amz-SignedHeaders", valid_612918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612920: Call_GenerateClientCertificate_612909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_612920.validator(path, query, header, formData, body)
  let scheme = call_612920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612920.url(scheme.get, call_612920.host, call_612920.base,
                         call_612920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612920, url, valid)

proc call*(call_612921: Call_GenerateClientCertificate_612909; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_612922 = newJObject()
  if body != nil:
    body_612922 = body
  result = call_612921.call(nil, nil, nil, nil, body_612922)

var generateClientCertificate* = Call_GenerateClientCertificate_612909(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_612910, base: "/",
    url: url_GenerateClientCertificate_612911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_612894 = ref object of OpenApiRestCall_610642
proc url_GetClientCertificates_612896(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClientCertificates_612895(path: JsonNode; query: JsonNode;
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
  var valid_612897 = query.getOrDefault("limit")
  valid_612897 = validateParameter(valid_612897, JInt, required = false, default = nil)
  if valid_612897 != nil:
    section.add "limit", valid_612897
  var valid_612898 = query.getOrDefault("position")
  valid_612898 = validateParameter(valid_612898, JString, required = false,
                                 default = nil)
  if valid_612898 != nil:
    section.add "position", valid_612898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612899 = header.getOrDefault("X-Amz-Signature")
  valid_612899 = validateParameter(valid_612899, JString, required = false,
                                 default = nil)
  if valid_612899 != nil:
    section.add "X-Amz-Signature", valid_612899
  var valid_612900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612900 = validateParameter(valid_612900, JString, required = false,
                                 default = nil)
  if valid_612900 != nil:
    section.add "X-Amz-Content-Sha256", valid_612900
  var valid_612901 = header.getOrDefault("X-Amz-Date")
  valid_612901 = validateParameter(valid_612901, JString, required = false,
                                 default = nil)
  if valid_612901 != nil:
    section.add "X-Amz-Date", valid_612901
  var valid_612902 = header.getOrDefault("X-Amz-Credential")
  valid_612902 = validateParameter(valid_612902, JString, required = false,
                                 default = nil)
  if valid_612902 != nil:
    section.add "X-Amz-Credential", valid_612902
  var valid_612903 = header.getOrDefault("X-Amz-Security-Token")
  valid_612903 = validateParameter(valid_612903, JString, required = false,
                                 default = nil)
  if valid_612903 != nil:
    section.add "X-Amz-Security-Token", valid_612903
  var valid_612904 = header.getOrDefault("X-Amz-Algorithm")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Algorithm", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-SignedHeaders", valid_612905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612906: Call_GetClientCertificates_612894; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_612906.validator(path, query, header, formData, body)
  let scheme = call_612906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612906.url(scheme.get, call_612906.host, call_612906.base,
                         call_612906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612906, url, valid)

proc call*(call_612907: Call_GetClientCertificates_612894; limit: int = 0;
          position: string = ""): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_612908 = newJObject()
  add(query_612908, "limit", newJInt(limit))
  add(query_612908, "position", newJString(position))
  result = call_612907.call(nil, query_612908, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_612894(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_612895, base: "/",
    url: url_GetClientCertificates_612896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_612923 = ref object of OpenApiRestCall_610642
proc url_GetAccount_612925(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccount_612924(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612926 = header.getOrDefault("X-Amz-Signature")
  valid_612926 = validateParameter(valid_612926, JString, required = false,
                                 default = nil)
  if valid_612926 != nil:
    section.add "X-Amz-Signature", valid_612926
  var valid_612927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612927 = validateParameter(valid_612927, JString, required = false,
                                 default = nil)
  if valid_612927 != nil:
    section.add "X-Amz-Content-Sha256", valid_612927
  var valid_612928 = header.getOrDefault("X-Amz-Date")
  valid_612928 = validateParameter(valid_612928, JString, required = false,
                                 default = nil)
  if valid_612928 != nil:
    section.add "X-Amz-Date", valid_612928
  var valid_612929 = header.getOrDefault("X-Amz-Credential")
  valid_612929 = validateParameter(valid_612929, JString, required = false,
                                 default = nil)
  if valid_612929 != nil:
    section.add "X-Amz-Credential", valid_612929
  var valid_612930 = header.getOrDefault("X-Amz-Security-Token")
  valid_612930 = validateParameter(valid_612930, JString, required = false,
                                 default = nil)
  if valid_612930 != nil:
    section.add "X-Amz-Security-Token", valid_612930
  var valid_612931 = header.getOrDefault("X-Amz-Algorithm")
  valid_612931 = validateParameter(valid_612931, JString, required = false,
                                 default = nil)
  if valid_612931 != nil:
    section.add "X-Amz-Algorithm", valid_612931
  var valid_612932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612932 = validateParameter(valid_612932, JString, required = false,
                                 default = nil)
  if valid_612932 != nil:
    section.add "X-Amz-SignedHeaders", valid_612932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612933: Call_GetAccount_612923; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_612933.validator(path, query, header, formData, body)
  let scheme = call_612933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612933.url(scheme.get, call_612933.host, call_612933.base,
                         call_612933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612933, url, valid)

proc call*(call_612934: Call_GetAccount_612923): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_612934.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_612923(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_612924,
                                      base: "/", url: url_GetAccount_612925,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_612935 = ref object of OpenApiRestCall_610642
proc url_UpdateAccount_612937(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAccount_612936(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612938 = header.getOrDefault("X-Amz-Signature")
  valid_612938 = validateParameter(valid_612938, JString, required = false,
                                 default = nil)
  if valid_612938 != nil:
    section.add "X-Amz-Signature", valid_612938
  var valid_612939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612939 = validateParameter(valid_612939, JString, required = false,
                                 default = nil)
  if valid_612939 != nil:
    section.add "X-Amz-Content-Sha256", valid_612939
  var valid_612940 = header.getOrDefault("X-Amz-Date")
  valid_612940 = validateParameter(valid_612940, JString, required = false,
                                 default = nil)
  if valid_612940 != nil:
    section.add "X-Amz-Date", valid_612940
  var valid_612941 = header.getOrDefault("X-Amz-Credential")
  valid_612941 = validateParameter(valid_612941, JString, required = false,
                                 default = nil)
  if valid_612941 != nil:
    section.add "X-Amz-Credential", valid_612941
  var valid_612942 = header.getOrDefault("X-Amz-Security-Token")
  valid_612942 = validateParameter(valid_612942, JString, required = false,
                                 default = nil)
  if valid_612942 != nil:
    section.add "X-Amz-Security-Token", valid_612942
  var valid_612943 = header.getOrDefault("X-Amz-Algorithm")
  valid_612943 = validateParameter(valid_612943, JString, required = false,
                                 default = nil)
  if valid_612943 != nil:
    section.add "X-Amz-Algorithm", valid_612943
  var valid_612944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612944 = validateParameter(valid_612944, JString, required = false,
                                 default = nil)
  if valid_612944 != nil:
    section.add "X-Amz-SignedHeaders", valid_612944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612946: Call_UpdateAccount_612935; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_612946.validator(path, query, header, formData, body)
  let scheme = call_612946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612946.url(scheme.get, call_612946.host, call_612946.base,
                         call_612946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612946, url, valid)

proc call*(call_612947: Call_UpdateAccount_612935; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_612948 = newJObject()
  if body != nil:
    body_612948 = body
  result = call_612947.call(nil, nil, nil, nil, body_612948)

var updateAccount* = Call_UpdateAccount_612935(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_612936, base: "/", url: url_UpdateAccount_612937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_612949 = ref object of OpenApiRestCall_610642
proc url_GetExport_612951(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetExport_612950(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612952 = path.getOrDefault("export_type")
  valid_612952 = validateParameter(valid_612952, JString, required = true,
                                 default = nil)
  if valid_612952 != nil:
    section.add "export_type", valid_612952
  var valid_612953 = path.getOrDefault("restapi_id")
  valid_612953 = validateParameter(valid_612953, JString, required = true,
                                 default = nil)
  if valid_612953 != nil:
    section.add "restapi_id", valid_612953
  var valid_612954 = path.getOrDefault("stage_name")
  valid_612954 = validateParameter(valid_612954, JString, required = true,
                                 default = nil)
  if valid_612954 != nil:
    section.add "stage_name", valid_612954
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_612955 = query.getOrDefault("parameters.2.value")
  valid_612955 = validateParameter(valid_612955, JString, required = false,
                                 default = nil)
  if valid_612955 != nil:
    section.add "parameters.2.value", valid_612955
  var valid_612956 = query.getOrDefault("parameters.1.value")
  valid_612956 = validateParameter(valid_612956, JString, required = false,
                                 default = nil)
  if valid_612956 != nil:
    section.add "parameters.1.value", valid_612956
  var valid_612957 = query.getOrDefault("parameters.1.key")
  valid_612957 = validateParameter(valid_612957, JString, required = false,
                                 default = nil)
  if valid_612957 != nil:
    section.add "parameters.1.key", valid_612957
  var valid_612958 = query.getOrDefault("parameters.2.key")
  valid_612958 = validateParameter(valid_612958, JString, required = false,
                                 default = nil)
  if valid_612958 != nil:
    section.add "parameters.2.key", valid_612958
  var valid_612959 = query.getOrDefault("parameters.0.value")
  valid_612959 = validateParameter(valid_612959, JString, required = false,
                                 default = nil)
  if valid_612959 != nil:
    section.add "parameters.0.value", valid_612959
  var valid_612960 = query.getOrDefault("parameters.0.key")
  valid_612960 = validateParameter(valid_612960, JString, required = false,
                                 default = nil)
  if valid_612960 != nil:
    section.add "parameters.0.key", valid_612960
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
  var valid_612961 = header.getOrDefault("X-Amz-Signature")
  valid_612961 = validateParameter(valid_612961, JString, required = false,
                                 default = nil)
  if valid_612961 != nil:
    section.add "X-Amz-Signature", valid_612961
  var valid_612962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612962 = validateParameter(valid_612962, JString, required = false,
                                 default = nil)
  if valid_612962 != nil:
    section.add "X-Amz-Content-Sha256", valid_612962
  var valid_612963 = header.getOrDefault("X-Amz-Date")
  valid_612963 = validateParameter(valid_612963, JString, required = false,
                                 default = nil)
  if valid_612963 != nil:
    section.add "X-Amz-Date", valid_612963
  var valid_612964 = header.getOrDefault("X-Amz-Credential")
  valid_612964 = validateParameter(valid_612964, JString, required = false,
                                 default = nil)
  if valid_612964 != nil:
    section.add "X-Amz-Credential", valid_612964
  var valid_612965 = header.getOrDefault("X-Amz-Security-Token")
  valid_612965 = validateParameter(valid_612965, JString, required = false,
                                 default = nil)
  if valid_612965 != nil:
    section.add "X-Amz-Security-Token", valid_612965
  var valid_612966 = header.getOrDefault("X-Amz-Algorithm")
  valid_612966 = validateParameter(valid_612966, JString, required = false,
                                 default = nil)
  if valid_612966 != nil:
    section.add "X-Amz-Algorithm", valid_612966
  var valid_612967 = header.getOrDefault("Accept")
  valid_612967 = validateParameter(valid_612967, JString, required = false,
                                 default = nil)
  if valid_612967 != nil:
    section.add "Accept", valid_612967
  var valid_612968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612968 = validateParameter(valid_612968, JString, required = false,
                                 default = nil)
  if valid_612968 != nil:
    section.add "X-Amz-SignedHeaders", valid_612968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612969: Call_GetExport_612949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_612969.validator(path, query, header, formData, body)
  let scheme = call_612969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612969.url(scheme.get, call_612969.host, call_612969.base,
                         call_612969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612969, url, valid)

proc call*(call_612970: Call_GetExport_612949; exportType: string; restapiId: string;
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
  var path_612971 = newJObject()
  var query_612972 = newJObject()
  add(query_612972, "parameters.2.value", newJString(parameters2Value))
  add(query_612972, "parameters.1.value", newJString(parameters1Value))
  add(query_612972, "parameters.1.key", newJString(parameters1Key))
  add(path_612971, "export_type", newJString(exportType))
  add(path_612971, "restapi_id", newJString(restapiId))
  add(query_612972, "parameters.2.key", newJString(parameters2Key))
  add(path_612971, "stage_name", newJString(stageName))
  add(query_612972, "parameters.0.value", newJString(parameters0Value))
  add(query_612972, "parameters.0.key", newJString(parameters0Key))
  result = call_612970.call(path_612971, query_612972, nil, nil, nil)

var getExport* = Call_GetExport_612949(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_612950,
                                    base: "/", url: url_GetExport_612951,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_612973 = ref object of OpenApiRestCall_610642
proc url_GetGatewayResponses_612975(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGatewayResponses_612974(path: JsonNode; query: JsonNode;
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
  var valid_612976 = path.getOrDefault("restapi_id")
  valid_612976 = validateParameter(valid_612976, JString, required = true,
                                 default = nil)
  if valid_612976 != nil:
    section.add "restapi_id", valid_612976
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  section = newJObject()
  var valid_612977 = query.getOrDefault("limit")
  valid_612977 = validateParameter(valid_612977, JInt, required = false, default = nil)
  if valid_612977 != nil:
    section.add "limit", valid_612977
  var valid_612978 = query.getOrDefault("position")
  valid_612978 = validateParameter(valid_612978, JString, required = false,
                                 default = nil)
  if valid_612978 != nil:
    section.add "position", valid_612978
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612979 = header.getOrDefault("X-Amz-Signature")
  valid_612979 = validateParameter(valid_612979, JString, required = false,
                                 default = nil)
  if valid_612979 != nil:
    section.add "X-Amz-Signature", valid_612979
  var valid_612980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612980 = validateParameter(valid_612980, JString, required = false,
                                 default = nil)
  if valid_612980 != nil:
    section.add "X-Amz-Content-Sha256", valid_612980
  var valid_612981 = header.getOrDefault("X-Amz-Date")
  valid_612981 = validateParameter(valid_612981, JString, required = false,
                                 default = nil)
  if valid_612981 != nil:
    section.add "X-Amz-Date", valid_612981
  var valid_612982 = header.getOrDefault("X-Amz-Credential")
  valid_612982 = validateParameter(valid_612982, JString, required = false,
                                 default = nil)
  if valid_612982 != nil:
    section.add "X-Amz-Credential", valid_612982
  var valid_612983 = header.getOrDefault("X-Amz-Security-Token")
  valid_612983 = validateParameter(valid_612983, JString, required = false,
                                 default = nil)
  if valid_612983 != nil:
    section.add "X-Amz-Security-Token", valid_612983
  var valid_612984 = header.getOrDefault("X-Amz-Algorithm")
  valid_612984 = validateParameter(valid_612984, JString, required = false,
                                 default = nil)
  if valid_612984 != nil:
    section.add "X-Amz-Algorithm", valid_612984
  var valid_612985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612985 = validateParameter(valid_612985, JString, required = false,
                                 default = nil)
  if valid_612985 != nil:
    section.add "X-Amz-SignedHeaders", valid_612985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612986: Call_GetGatewayResponses_612973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_612986.validator(path, query, header, formData, body)
  let scheme = call_612986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612986.url(scheme.get, call_612986.host, call_612986.base,
                         call_612986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612986, url, valid)

proc call*(call_612987: Call_GetGatewayResponses_612973; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_612988 = newJObject()
  var query_612989 = newJObject()
  add(query_612989, "limit", newJInt(limit))
  add(query_612989, "position", newJString(position))
  add(path_612988, "restapi_id", newJString(restapiId))
  result = call_612987.call(path_612988, query_612989, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_612973(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_612974, base: "/",
    url: url_GetGatewayResponses_612975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_612990 = ref object of OpenApiRestCall_610642
proc url_GetModelTemplate_612992(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModelTemplate_612991(path: JsonNode; query: JsonNode;
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
  var valid_612993 = path.getOrDefault("model_name")
  valid_612993 = validateParameter(valid_612993, JString, required = true,
                                 default = nil)
  if valid_612993 != nil:
    section.add "model_name", valid_612993
  var valid_612994 = path.getOrDefault("restapi_id")
  valid_612994 = validateParameter(valid_612994, JString, required = true,
                                 default = nil)
  if valid_612994 != nil:
    section.add "restapi_id", valid_612994
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612995 = header.getOrDefault("X-Amz-Signature")
  valid_612995 = validateParameter(valid_612995, JString, required = false,
                                 default = nil)
  if valid_612995 != nil:
    section.add "X-Amz-Signature", valid_612995
  var valid_612996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612996 = validateParameter(valid_612996, JString, required = false,
                                 default = nil)
  if valid_612996 != nil:
    section.add "X-Amz-Content-Sha256", valid_612996
  var valid_612997 = header.getOrDefault("X-Amz-Date")
  valid_612997 = validateParameter(valid_612997, JString, required = false,
                                 default = nil)
  if valid_612997 != nil:
    section.add "X-Amz-Date", valid_612997
  var valid_612998 = header.getOrDefault("X-Amz-Credential")
  valid_612998 = validateParameter(valid_612998, JString, required = false,
                                 default = nil)
  if valid_612998 != nil:
    section.add "X-Amz-Credential", valid_612998
  var valid_612999 = header.getOrDefault("X-Amz-Security-Token")
  valid_612999 = validateParameter(valid_612999, JString, required = false,
                                 default = nil)
  if valid_612999 != nil:
    section.add "X-Amz-Security-Token", valid_612999
  var valid_613000 = header.getOrDefault("X-Amz-Algorithm")
  valid_613000 = validateParameter(valid_613000, JString, required = false,
                                 default = nil)
  if valid_613000 != nil:
    section.add "X-Amz-Algorithm", valid_613000
  var valid_613001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613001 = validateParameter(valid_613001, JString, required = false,
                                 default = nil)
  if valid_613001 != nil:
    section.add "X-Amz-SignedHeaders", valid_613001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613002: Call_GetModelTemplate_612990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_613002.validator(path, query, header, formData, body)
  let scheme = call_613002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613002.url(scheme.get, call_613002.host, call_613002.base,
                         call_613002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613002, url, valid)

proc call*(call_613003: Call_GetModelTemplate_612990; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_613004 = newJObject()
  add(path_613004, "model_name", newJString(modelName))
  add(path_613004, "restapi_id", newJString(restapiId))
  result = call_613003.call(path_613004, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_612990(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_612991, base: "/",
    url: url_GetModelTemplate_612992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_613005 = ref object of OpenApiRestCall_610642
proc url_GetResources_613007(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResources_613006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613008 = path.getOrDefault("restapi_id")
  valid_613008 = validateParameter(valid_613008, JString, required = true,
                                 default = nil)
  if valid_613008 != nil:
    section.add "restapi_id", valid_613008
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  section = newJObject()
  var valid_613009 = query.getOrDefault("limit")
  valid_613009 = validateParameter(valid_613009, JInt, required = false, default = nil)
  if valid_613009 != nil:
    section.add "limit", valid_613009
  var valid_613010 = query.getOrDefault("position")
  valid_613010 = validateParameter(valid_613010, JString, required = false,
                                 default = nil)
  if valid_613010 != nil:
    section.add "position", valid_613010
  var valid_613011 = query.getOrDefault("embed")
  valid_613011 = validateParameter(valid_613011, JArray, required = false,
                                 default = nil)
  if valid_613011 != nil:
    section.add "embed", valid_613011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613012 = header.getOrDefault("X-Amz-Signature")
  valid_613012 = validateParameter(valid_613012, JString, required = false,
                                 default = nil)
  if valid_613012 != nil:
    section.add "X-Amz-Signature", valid_613012
  var valid_613013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613013 = validateParameter(valid_613013, JString, required = false,
                                 default = nil)
  if valid_613013 != nil:
    section.add "X-Amz-Content-Sha256", valid_613013
  var valid_613014 = header.getOrDefault("X-Amz-Date")
  valid_613014 = validateParameter(valid_613014, JString, required = false,
                                 default = nil)
  if valid_613014 != nil:
    section.add "X-Amz-Date", valid_613014
  var valid_613015 = header.getOrDefault("X-Amz-Credential")
  valid_613015 = validateParameter(valid_613015, JString, required = false,
                                 default = nil)
  if valid_613015 != nil:
    section.add "X-Amz-Credential", valid_613015
  var valid_613016 = header.getOrDefault("X-Amz-Security-Token")
  valid_613016 = validateParameter(valid_613016, JString, required = false,
                                 default = nil)
  if valid_613016 != nil:
    section.add "X-Amz-Security-Token", valid_613016
  var valid_613017 = header.getOrDefault("X-Amz-Algorithm")
  valid_613017 = validateParameter(valid_613017, JString, required = false,
                                 default = nil)
  if valid_613017 != nil:
    section.add "X-Amz-Algorithm", valid_613017
  var valid_613018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613018 = validateParameter(valid_613018, JString, required = false,
                                 default = nil)
  if valid_613018 != nil:
    section.add "X-Amz-SignedHeaders", valid_613018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613019: Call_GetResources_613005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_613019.validator(path, query, header, formData, body)
  let scheme = call_613019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613019.url(scheme.get, call_613019.host, call_613019.base,
                         call_613019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613019, url, valid)

proc call*(call_613020: Call_GetResources_613005; restapiId: string; limit: int = 0;
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
  var path_613021 = newJObject()
  var query_613022 = newJObject()
  add(query_613022, "limit", newJInt(limit))
  add(query_613022, "position", newJString(position))
  add(path_613021, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_613022.add "embed", embed
  result = call_613020.call(path_613021, query_613022, nil, nil, nil)

var getResources* = Call_GetResources_613005(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_613006,
    base: "/", url: url_GetResources_613007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_613023 = ref object of OpenApiRestCall_610642
proc url_GetSdk_613025(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSdk_613024(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613026 = path.getOrDefault("sdk_type")
  valid_613026 = validateParameter(valid_613026, JString, required = true,
                                 default = nil)
  if valid_613026 != nil:
    section.add "sdk_type", valid_613026
  var valid_613027 = path.getOrDefault("restapi_id")
  valid_613027 = validateParameter(valid_613027, JString, required = true,
                                 default = nil)
  if valid_613027 != nil:
    section.add "restapi_id", valid_613027
  var valid_613028 = path.getOrDefault("stage_name")
  valid_613028 = validateParameter(valid_613028, JString, required = true,
                                 default = nil)
  if valid_613028 != nil:
    section.add "stage_name", valid_613028
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_613029 = query.getOrDefault("parameters.2.value")
  valid_613029 = validateParameter(valid_613029, JString, required = false,
                                 default = nil)
  if valid_613029 != nil:
    section.add "parameters.2.value", valid_613029
  var valid_613030 = query.getOrDefault("parameters.1.value")
  valid_613030 = validateParameter(valid_613030, JString, required = false,
                                 default = nil)
  if valid_613030 != nil:
    section.add "parameters.1.value", valid_613030
  var valid_613031 = query.getOrDefault("parameters.1.key")
  valid_613031 = validateParameter(valid_613031, JString, required = false,
                                 default = nil)
  if valid_613031 != nil:
    section.add "parameters.1.key", valid_613031
  var valid_613032 = query.getOrDefault("parameters.2.key")
  valid_613032 = validateParameter(valid_613032, JString, required = false,
                                 default = nil)
  if valid_613032 != nil:
    section.add "parameters.2.key", valid_613032
  var valid_613033 = query.getOrDefault("parameters.0.value")
  valid_613033 = validateParameter(valid_613033, JString, required = false,
                                 default = nil)
  if valid_613033 != nil:
    section.add "parameters.0.value", valid_613033
  var valid_613034 = query.getOrDefault("parameters.0.key")
  valid_613034 = validateParameter(valid_613034, JString, required = false,
                                 default = nil)
  if valid_613034 != nil:
    section.add "parameters.0.key", valid_613034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613035 = header.getOrDefault("X-Amz-Signature")
  valid_613035 = validateParameter(valid_613035, JString, required = false,
                                 default = nil)
  if valid_613035 != nil:
    section.add "X-Amz-Signature", valid_613035
  var valid_613036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613036 = validateParameter(valid_613036, JString, required = false,
                                 default = nil)
  if valid_613036 != nil:
    section.add "X-Amz-Content-Sha256", valid_613036
  var valid_613037 = header.getOrDefault("X-Amz-Date")
  valid_613037 = validateParameter(valid_613037, JString, required = false,
                                 default = nil)
  if valid_613037 != nil:
    section.add "X-Amz-Date", valid_613037
  var valid_613038 = header.getOrDefault("X-Amz-Credential")
  valid_613038 = validateParameter(valid_613038, JString, required = false,
                                 default = nil)
  if valid_613038 != nil:
    section.add "X-Amz-Credential", valid_613038
  var valid_613039 = header.getOrDefault("X-Amz-Security-Token")
  valid_613039 = validateParameter(valid_613039, JString, required = false,
                                 default = nil)
  if valid_613039 != nil:
    section.add "X-Amz-Security-Token", valid_613039
  var valid_613040 = header.getOrDefault("X-Amz-Algorithm")
  valid_613040 = validateParameter(valid_613040, JString, required = false,
                                 default = nil)
  if valid_613040 != nil:
    section.add "X-Amz-Algorithm", valid_613040
  var valid_613041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613041 = validateParameter(valid_613041, JString, required = false,
                                 default = nil)
  if valid_613041 != nil:
    section.add "X-Amz-SignedHeaders", valid_613041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613042: Call_GetSdk_613023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_613042.validator(path, query, header, formData, body)
  let scheme = call_613042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613042.url(scheme.get, call_613042.host, call_613042.base,
                         call_613042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613042, url, valid)

proc call*(call_613043: Call_GetSdk_613023; sdkType: string; restapiId: string;
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
  var path_613044 = newJObject()
  var query_613045 = newJObject()
  add(path_613044, "sdk_type", newJString(sdkType))
  add(query_613045, "parameters.2.value", newJString(parameters2Value))
  add(query_613045, "parameters.1.value", newJString(parameters1Value))
  add(query_613045, "parameters.1.key", newJString(parameters1Key))
  add(path_613044, "restapi_id", newJString(restapiId))
  add(query_613045, "parameters.2.key", newJString(parameters2Key))
  add(path_613044, "stage_name", newJString(stageName))
  add(query_613045, "parameters.0.value", newJString(parameters0Value))
  add(query_613045, "parameters.0.key", newJString(parameters0Key))
  result = call_613043.call(path_613044, query_613045, nil, nil, nil)

var getSdk* = Call_GetSdk_613023(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_613024, base: "/",
                              url: url_GetSdk_613025,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_613046 = ref object of OpenApiRestCall_610642
proc url_GetSdkType_613048(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSdkType_613047(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_613049 = path.getOrDefault("sdktype_id")
  valid_613049 = validateParameter(valid_613049, JString, required = true,
                                 default = nil)
  if valid_613049 != nil:
    section.add "sdktype_id", valid_613049
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613050 = header.getOrDefault("X-Amz-Signature")
  valid_613050 = validateParameter(valid_613050, JString, required = false,
                                 default = nil)
  if valid_613050 != nil:
    section.add "X-Amz-Signature", valid_613050
  var valid_613051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613051 = validateParameter(valid_613051, JString, required = false,
                                 default = nil)
  if valid_613051 != nil:
    section.add "X-Amz-Content-Sha256", valid_613051
  var valid_613052 = header.getOrDefault("X-Amz-Date")
  valid_613052 = validateParameter(valid_613052, JString, required = false,
                                 default = nil)
  if valid_613052 != nil:
    section.add "X-Amz-Date", valid_613052
  var valid_613053 = header.getOrDefault("X-Amz-Credential")
  valid_613053 = validateParameter(valid_613053, JString, required = false,
                                 default = nil)
  if valid_613053 != nil:
    section.add "X-Amz-Credential", valid_613053
  var valid_613054 = header.getOrDefault("X-Amz-Security-Token")
  valid_613054 = validateParameter(valid_613054, JString, required = false,
                                 default = nil)
  if valid_613054 != nil:
    section.add "X-Amz-Security-Token", valid_613054
  var valid_613055 = header.getOrDefault("X-Amz-Algorithm")
  valid_613055 = validateParameter(valid_613055, JString, required = false,
                                 default = nil)
  if valid_613055 != nil:
    section.add "X-Amz-Algorithm", valid_613055
  var valid_613056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613056 = validateParameter(valid_613056, JString, required = false,
                                 default = nil)
  if valid_613056 != nil:
    section.add "X-Amz-SignedHeaders", valid_613056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613057: Call_GetSdkType_613046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613057.validator(path, query, header, formData, body)
  let scheme = call_613057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613057.url(scheme.get, call_613057.host, call_613057.base,
                         call_613057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613057, url, valid)

proc call*(call_613058: Call_GetSdkType_613046; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_613059 = newJObject()
  add(path_613059, "sdktype_id", newJString(sdktypeId))
  result = call_613058.call(path_613059, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_613046(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_613047,
                                      base: "/", url: url_GetSdkType_613048,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_613060 = ref object of OpenApiRestCall_610642
proc url_GetSdkTypes_613062(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSdkTypes_613061(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613063 = query.getOrDefault("limit")
  valid_613063 = validateParameter(valid_613063, JInt, required = false, default = nil)
  if valid_613063 != nil:
    section.add "limit", valid_613063
  var valid_613064 = query.getOrDefault("position")
  valid_613064 = validateParameter(valid_613064, JString, required = false,
                                 default = nil)
  if valid_613064 != nil:
    section.add "position", valid_613064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613065 = header.getOrDefault("X-Amz-Signature")
  valid_613065 = validateParameter(valid_613065, JString, required = false,
                                 default = nil)
  if valid_613065 != nil:
    section.add "X-Amz-Signature", valid_613065
  var valid_613066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613066 = validateParameter(valid_613066, JString, required = false,
                                 default = nil)
  if valid_613066 != nil:
    section.add "X-Amz-Content-Sha256", valid_613066
  var valid_613067 = header.getOrDefault("X-Amz-Date")
  valid_613067 = validateParameter(valid_613067, JString, required = false,
                                 default = nil)
  if valid_613067 != nil:
    section.add "X-Amz-Date", valid_613067
  var valid_613068 = header.getOrDefault("X-Amz-Credential")
  valid_613068 = validateParameter(valid_613068, JString, required = false,
                                 default = nil)
  if valid_613068 != nil:
    section.add "X-Amz-Credential", valid_613068
  var valid_613069 = header.getOrDefault("X-Amz-Security-Token")
  valid_613069 = validateParameter(valid_613069, JString, required = false,
                                 default = nil)
  if valid_613069 != nil:
    section.add "X-Amz-Security-Token", valid_613069
  var valid_613070 = header.getOrDefault("X-Amz-Algorithm")
  valid_613070 = validateParameter(valid_613070, JString, required = false,
                                 default = nil)
  if valid_613070 != nil:
    section.add "X-Amz-Algorithm", valid_613070
  var valid_613071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613071 = validateParameter(valid_613071, JString, required = false,
                                 default = nil)
  if valid_613071 != nil:
    section.add "X-Amz-SignedHeaders", valid_613071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613072: Call_GetSdkTypes_613060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613072.validator(path, query, header, formData, body)
  let scheme = call_613072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613072.url(scheme.get, call_613072.host, call_613072.base,
                         call_613072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613072, url, valid)

proc call*(call_613073: Call_GetSdkTypes_613060; limit: int = 0; position: string = ""): Recallable =
  ## getSdkTypes
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_613074 = newJObject()
  add(query_613074, "limit", newJInt(limit))
  add(query_613074, "position", newJString(position))
  result = call_613073.call(nil, query_613074, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_613060(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_613061,
                                        base: "/", url: url_GetSdkTypes_613062,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613092 = ref object of OpenApiRestCall_610642
proc url_TagResource_613094(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613093(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613095 = path.getOrDefault("resource_arn")
  valid_613095 = validateParameter(valid_613095, JString, required = true,
                                 default = nil)
  if valid_613095 != nil:
    section.add "resource_arn", valid_613095
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613096 = header.getOrDefault("X-Amz-Signature")
  valid_613096 = validateParameter(valid_613096, JString, required = false,
                                 default = nil)
  if valid_613096 != nil:
    section.add "X-Amz-Signature", valid_613096
  var valid_613097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "X-Amz-Content-Sha256", valid_613097
  var valid_613098 = header.getOrDefault("X-Amz-Date")
  valid_613098 = validateParameter(valid_613098, JString, required = false,
                                 default = nil)
  if valid_613098 != nil:
    section.add "X-Amz-Date", valid_613098
  var valid_613099 = header.getOrDefault("X-Amz-Credential")
  valid_613099 = validateParameter(valid_613099, JString, required = false,
                                 default = nil)
  if valid_613099 != nil:
    section.add "X-Amz-Credential", valid_613099
  var valid_613100 = header.getOrDefault("X-Amz-Security-Token")
  valid_613100 = validateParameter(valid_613100, JString, required = false,
                                 default = nil)
  if valid_613100 != nil:
    section.add "X-Amz-Security-Token", valid_613100
  var valid_613101 = header.getOrDefault("X-Amz-Algorithm")
  valid_613101 = validateParameter(valid_613101, JString, required = false,
                                 default = nil)
  if valid_613101 != nil:
    section.add "X-Amz-Algorithm", valid_613101
  var valid_613102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613102 = validateParameter(valid_613102, JString, required = false,
                                 default = nil)
  if valid_613102 != nil:
    section.add "X-Amz-SignedHeaders", valid_613102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613104: Call_TagResource_613092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_613104.validator(path, query, header, formData, body)
  let scheme = call_613104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613104.url(scheme.get, call_613104.host, call_613104.base,
                         call_613104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613104, url, valid)

proc call*(call_613105: Call_TagResource_613092; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_613106 = newJObject()
  var body_613107 = newJObject()
  add(path_613106, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_613107 = body
  result = call_613105.call(path_613106, nil, nil, nil, body_613107)

var tagResource* = Call_TagResource_613092(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_613093,
                                        base: "/", url: url_TagResource_613094,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_613075 = ref object of OpenApiRestCall_610642
proc url_GetTags_613077(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTags_613076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613078 = path.getOrDefault("resource_arn")
  valid_613078 = validateParameter(valid_613078, JString, required = true,
                                 default = nil)
  if valid_613078 != nil:
    section.add "resource_arn", valid_613078
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  section = newJObject()
  var valid_613079 = query.getOrDefault("limit")
  valid_613079 = validateParameter(valid_613079, JInt, required = false, default = nil)
  if valid_613079 != nil:
    section.add "limit", valid_613079
  var valid_613080 = query.getOrDefault("position")
  valid_613080 = validateParameter(valid_613080, JString, required = false,
                                 default = nil)
  if valid_613080 != nil:
    section.add "position", valid_613080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613081 = header.getOrDefault("X-Amz-Signature")
  valid_613081 = validateParameter(valid_613081, JString, required = false,
                                 default = nil)
  if valid_613081 != nil:
    section.add "X-Amz-Signature", valid_613081
  var valid_613082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613082 = validateParameter(valid_613082, JString, required = false,
                                 default = nil)
  if valid_613082 != nil:
    section.add "X-Amz-Content-Sha256", valid_613082
  var valid_613083 = header.getOrDefault("X-Amz-Date")
  valid_613083 = validateParameter(valid_613083, JString, required = false,
                                 default = nil)
  if valid_613083 != nil:
    section.add "X-Amz-Date", valid_613083
  var valid_613084 = header.getOrDefault("X-Amz-Credential")
  valid_613084 = validateParameter(valid_613084, JString, required = false,
                                 default = nil)
  if valid_613084 != nil:
    section.add "X-Amz-Credential", valid_613084
  var valid_613085 = header.getOrDefault("X-Amz-Security-Token")
  valid_613085 = validateParameter(valid_613085, JString, required = false,
                                 default = nil)
  if valid_613085 != nil:
    section.add "X-Amz-Security-Token", valid_613085
  var valid_613086 = header.getOrDefault("X-Amz-Algorithm")
  valid_613086 = validateParameter(valid_613086, JString, required = false,
                                 default = nil)
  if valid_613086 != nil:
    section.add "X-Amz-Algorithm", valid_613086
  var valid_613087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613087 = validateParameter(valid_613087, JString, required = false,
                                 default = nil)
  if valid_613087 != nil:
    section.add "X-Amz-SignedHeaders", valid_613087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613088: Call_GetTags_613075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_613088.validator(path, query, header, formData, body)
  let scheme = call_613088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613088.url(scheme.get, call_613088.host, call_613088.base,
                         call_613088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613088, url, valid)

proc call*(call_613089: Call_GetTags_613075; resourceArn: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  var path_613090 = newJObject()
  var query_613091 = newJObject()
  add(query_613091, "limit", newJInt(limit))
  add(path_613090, "resource_arn", newJString(resourceArn))
  add(query_613091, "position", newJString(position))
  result = call_613089.call(path_613090, query_613091, nil, nil, nil)

var getTags* = Call_GetTags_613075(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_613076, base: "/",
                                url: url_GetTags_613077,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_613108 = ref object of OpenApiRestCall_610642
proc url_GetUsage_613110(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUsage_613109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613111 = path.getOrDefault("usageplanId")
  valid_613111 = validateParameter(valid_613111, JString, required = true,
                                 default = nil)
  if valid_613111 != nil:
    section.add "usageplanId", valid_613111
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
  var valid_613112 = query.getOrDefault("limit")
  valid_613112 = validateParameter(valid_613112, JInt, required = false, default = nil)
  if valid_613112 != nil:
    section.add "limit", valid_613112
  assert query != nil, "query argument is necessary due to required `endDate` field"
  var valid_613113 = query.getOrDefault("endDate")
  valid_613113 = validateParameter(valid_613113, JString, required = true,
                                 default = nil)
  if valid_613113 != nil:
    section.add "endDate", valid_613113
  var valid_613114 = query.getOrDefault("position")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "position", valid_613114
  var valid_613115 = query.getOrDefault("keyId")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "keyId", valid_613115
  var valid_613116 = query.getOrDefault("startDate")
  valid_613116 = validateParameter(valid_613116, JString, required = true,
                                 default = nil)
  if valid_613116 != nil:
    section.add "startDate", valid_613116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613117 = header.getOrDefault("X-Amz-Signature")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Signature", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Content-Sha256", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Date")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Date", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Credential")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Credential", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Security-Token")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Security-Token", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-Algorithm")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-Algorithm", valid_613122
  var valid_613123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613123 = validateParameter(valid_613123, JString, required = false,
                                 default = nil)
  if valid_613123 != nil:
    section.add "X-Amz-SignedHeaders", valid_613123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613124: Call_GetUsage_613108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_613124.validator(path, query, header, formData, body)
  let scheme = call_613124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613124.url(scheme.get, call_613124.host, call_613124.base,
                         call_613124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613124, url, valid)

proc call*(call_613125: Call_GetUsage_613108; usageplanId: string; endDate: string;
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
  var path_613126 = newJObject()
  var query_613127 = newJObject()
  add(path_613126, "usageplanId", newJString(usageplanId))
  add(query_613127, "limit", newJInt(limit))
  add(query_613127, "endDate", newJString(endDate))
  add(query_613127, "position", newJString(position))
  add(query_613127, "keyId", newJString(keyId))
  add(query_613127, "startDate", newJString(startDate))
  result = call_613125.call(path_613126, query_613127, nil, nil, nil)

var getUsage* = Call_GetUsage_613108(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_613109, base: "/",
                                  url: url_GetUsage_613110,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_613128 = ref object of OpenApiRestCall_610642
proc url_ImportApiKeys_613130(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApiKeys_613129(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613131 = query.getOrDefault("failonwarnings")
  valid_613131 = validateParameter(valid_613131, JBool, required = false, default = nil)
  if valid_613131 != nil:
    section.add "failonwarnings", valid_613131
  var valid_613132 = query.getOrDefault("mode")
  valid_613132 = validateParameter(valid_613132, JString, required = true,
                                 default = newJString("import"))
  if valid_613132 != nil:
    section.add "mode", valid_613132
  var valid_613133 = query.getOrDefault("format")
  valid_613133 = validateParameter(valid_613133, JString, required = true,
                                 default = newJString("csv"))
  if valid_613133 != nil:
    section.add "format", valid_613133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613134 = header.getOrDefault("X-Amz-Signature")
  valid_613134 = validateParameter(valid_613134, JString, required = false,
                                 default = nil)
  if valid_613134 != nil:
    section.add "X-Amz-Signature", valid_613134
  var valid_613135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613135 = validateParameter(valid_613135, JString, required = false,
                                 default = nil)
  if valid_613135 != nil:
    section.add "X-Amz-Content-Sha256", valid_613135
  var valid_613136 = header.getOrDefault("X-Amz-Date")
  valid_613136 = validateParameter(valid_613136, JString, required = false,
                                 default = nil)
  if valid_613136 != nil:
    section.add "X-Amz-Date", valid_613136
  var valid_613137 = header.getOrDefault("X-Amz-Credential")
  valid_613137 = validateParameter(valid_613137, JString, required = false,
                                 default = nil)
  if valid_613137 != nil:
    section.add "X-Amz-Credential", valid_613137
  var valid_613138 = header.getOrDefault("X-Amz-Security-Token")
  valid_613138 = validateParameter(valid_613138, JString, required = false,
                                 default = nil)
  if valid_613138 != nil:
    section.add "X-Amz-Security-Token", valid_613138
  var valid_613139 = header.getOrDefault("X-Amz-Algorithm")
  valid_613139 = validateParameter(valid_613139, JString, required = false,
                                 default = nil)
  if valid_613139 != nil:
    section.add "X-Amz-Algorithm", valid_613139
  var valid_613140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613140 = validateParameter(valid_613140, JString, required = false,
                                 default = nil)
  if valid_613140 != nil:
    section.add "X-Amz-SignedHeaders", valid_613140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613142: Call_ImportApiKeys_613128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_613142.validator(path, query, header, formData, body)
  let scheme = call_613142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613142.url(scheme.get, call_613142.host, call_613142.base,
                         call_613142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613142, url, valid)

proc call*(call_613143: Call_ImportApiKeys_613128; body: JsonNode;
          failonwarnings: bool = false; mode: string = "import"; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   mode: string (required)
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_613144 = newJObject()
  var body_613145 = newJObject()
  add(query_613144, "failonwarnings", newJBool(failonwarnings))
  add(query_613144, "mode", newJString(mode))
  if body != nil:
    body_613145 = body
  add(query_613144, "format", newJString(format))
  result = call_613143.call(nil, query_613144, nil, nil, body_613145)

var importApiKeys* = Call_ImportApiKeys_613128(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_613129,
    base: "/", url: url_ImportApiKeys_613130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_613146 = ref object of OpenApiRestCall_610642
proc url_ImportRestApi_613148(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportRestApi_613147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613149 = query.getOrDefault("failonwarnings")
  valid_613149 = validateParameter(valid_613149, JBool, required = false, default = nil)
  if valid_613149 != nil:
    section.add "failonwarnings", valid_613149
  var valid_613150 = query.getOrDefault("parameters.2.value")
  valid_613150 = validateParameter(valid_613150, JString, required = false,
                                 default = nil)
  if valid_613150 != nil:
    section.add "parameters.2.value", valid_613150
  var valid_613151 = query.getOrDefault("parameters.1.value")
  valid_613151 = validateParameter(valid_613151, JString, required = false,
                                 default = nil)
  if valid_613151 != nil:
    section.add "parameters.1.value", valid_613151
  var valid_613152 = query.getOrDefault("mode")
  valid_613152 = validateParameter(valid_613152, JString, required = true,
                                 default = newJString("import"))
  if valid_613152 != nil:
    section.add "mode", valid_613152
  var valid_613153 = query.getOrDefault("parameters.1.key")
  valid_613153 = validateParameter(valid_613153, JString, required = false,
                                 default = nil)
  if valid_613153 != nil:
    section.add "parameters.1.key", valid_613153
  var valid_613154 = query.getOrDefault("parameters.2.key")
  valid_613154 = validateParameter(valid_613154, JString, required = false,
                                 default = nil)
  if valid_613154 != nil:
    section.add "parameters.2.key", valid_613154
  var valid_613155 = query.getOrDefault("parameters.0.value")
  valid_613155 = validateParameter(valid_613155, JString, required = false,
                                 default = nil)
  if valid_613155 != nil:
    section.add "parameters.0.value", valid_613155
  var valid_613156 = query.getOrDefault("parameters.0.key")
  valid_613156 = validateParameter(valid_613156, JString, required = false,
                                 default = nil)
  if valid_613156 != nil:
    section.add "parameters.0.key", valid_613156
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613157 = header.getOrDefault("X-Amz-Signature")
  valid_613157 = validateParameter(valid_613157, JString, required = false,
                                 default = nil)
  if valid_613157 != nil:
    section.add "X-Amz-Signature", valid_613157
  var valid_613158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613158 = validateParameter(valid_613158, JString, required = false,
                                 default = nil)
  if valid_613158 != nil:
    section.add "X-Amz-Content-Sha256", valid_613158
  var valid_613159 = header.getOrDefault("X-Amz-Date")
  valid_613159 = validateParameter(valid_613159, JString, required = false,
                                 default = nil)
  if valid_613159 != nil:
    section.add "X-Amz-Date", valid_613159
  var valid_613160 = header.getOrDefault("X-Amz-Credential")
  valid_613160 = validateParameter(valid_613160, JString, required = false,
                                 default = nil)
  if valid_613160 != nil:
    section.add "X-Amz-Credential", valid_613160
  var valid_613161 = header.getOrDefault("X-Amz-Security-Token")
  valid_613161 = validateParameter(valid_613161, JString, required = false,
                                 default = nil)
  if valid_613161 != nil:
    section.add "X-Amz-Security-Token", valid_613161
  var valid_613162 = header.getOrDefault("X-Amz-Algorithm")
  valid_613162 = validateParameter(valid_613162, JString, required = false,
                                 default = nil)
  if valid_613162 != nil:
    section.add "X-Amz-Algorithm", valid_613162
  var valid_613163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613163 = validateParameter(valid_613163, JString, required = false,
                                 default = nil)
  if valid_613163 != nil:
    section.add "X-Amz-SignedHeaders", valid_613163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613165: Call_ImportRestApi_613146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_613165.validator(path, query, header, formData, body)
  let scheme = call_613165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613165.url(scheme.get, call_613165.host, call_613165.base,
                         call_613165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613165, url, valid)

proc call*(call_613166: Call_ImportRestApi_613146; body: JsonNode;
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
  var query_613167 = newJObject()
  var body_613168 = newJObject()
  add(query_613167, "failonwarnings", newJBool(failonwarnings))
  add(query_613167, "parameters.2.value", newJString(parameters2Value))
  add(query_613167, "parameters.1.value", newJString(parameters1Value))
  add(query_613167, "mode", newJString(mode))
  add(query_613167, "parameters.1.key", newJString(parameters1Key))
  add(query_613167, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_613168 = body
  add(query_613167, "parameters.0.value", newJString(parameters0Value))
  add(query_613167, "parameters.0.key", newJString(parameters0Key))
  result = call_613166.call(nil, query_613167, nil, nil, body_613168)

var importRestApi* = Call_ImportRestApi_613146(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_613147,
    base: "/", url: url_ImportRestApi_613148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613169 = ref object of OpenApiRestCall_610642
proc url_UntagResource_613171(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613170(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613172 = path.getOrDefault("resource_arn")
  valid_613172 = validateParameter(valid_613172, JString, required = true,
                                 default = nil)
  if valid_613172 != nil:
    section.add "resource_arn", valid_613172
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613173 = query.getOrDefault("tagKeys")
  valid_613173 = validateParameter(valid_613173, JArray, required = true, default = nil)
  if valid_613173 != nil:
    section.add "tagKeys", valid_613173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613174 = header.getOrDefault("X-Amz-Signature")
  valid_613174 = validateParameter(valid_613174, JString, required = false,
                                 default = nil)
  if valid_613174 != nil:
    section.add "X-Amz-Signature", valid_613174
  var valid_613175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613175 = validateParameter(valid_613175, JString, required = false,
                                 default = nil)
  if valid_613175 != nil:
    section.add "X-Amz-Content-Sha256", valid_613175
  var valid_613176 = header.getOrDefault("X-Amz-Date")
  valid_613176 = validateParameter(valid_613176, JString, required = false,
                                 default = nil)
  if valid_613176 != nil:
    section.add "X-Amz-Date", valid_613176
  var valid_613177 = header.getOrDefault("X-Amz-Credential")
  valid_613177 = validateParameter(valid_613177, JString, required = false,
                                 default = nil)
  if valid_613177 != nil:
    section.add "X-Amz-Credential", valid_613177
  var valid_613178 = header.getOrDefault("X-Amz-Security-Token")
  valid_613178 = validateParameter(valid_613178, JString, required = false,
                                 default = nil)
  if valid_613178 != nil:
    section.add "X-Amz-Security-Token", valid_613178
  var valid_613179 = header.getOrDefault("X-Amz-Algorithm")
  valid_613179 = validateParameter(valid_613179, JString, required = false,
                                 default = nil)
  if valid_613179 != nil:
    section.add "X-Amz-Algorithm", valid_613179
  var valid_613180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613180 = validateParameter(valid_613180, JString, required = false,
                                 default = nil)
  if valid_613180 != nil:
    section.add "X-Amz-SignedHeaders", valid_613180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613181: Call_UntagResource_613169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_613181.validator(path, query, header, formData, body)
  let scheme = call_613181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613181.url(scheme.get, call_613181.host, call_613181.base,
                         call_613181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613181, url, valid)

proc call*(call_613182: Call_UntagResource_613169; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_613183 = newJObject()
  var query_613184 = newJObject()
  add(path_613183, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_613184.add "tagKeys", tagKeys
  result = call_613182.call(path_613183, query_613184, nil, nil, nil)

var untagResource* = Call_UntagResource_613169(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_613170,
    base: "/", url: url_UntagResource_613171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_613185 = ref object of OpenApiRestCall_610642
proc url_UpdateUsage_613187(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUsage_613186(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613188 = path.getOrDefault("usageplanId")
  valid_613188 = validateParameter(valid_613188, JString, required = true,
                                 default = nil)
  if valid_613188 != nil:
    section.add "usageplanId", valid_613188
  var valid_613189 = path.getOrDefault("keyId")
  valid_613189 = validateParameter(valid_613189, JString, required = true,
                                 default = nil)
  if valid_613189 != nil:
    section.add "keyId", valid_613189
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613190 = header.getOrDefault("X-Amz-Signature")
  valid_613190 = validateParameter(valid_613190, JString, required = false,
                                 default = nil)
  if valid_613190 != nil:
    section.add "X-Amz-Signature", valid_613190
  var valid_613191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613191 = validateParameter(valid_613191, JString, required = false,
                                 default = nil)
  if valid_613191 != nil:
    section.add "X-Amz-Content-Sha256", valid_613191
  var valid_613192 = header.getOrDefault("X-Amz-Date")
  valid_613192 = validateParameter(valid_613192, JString, required = false,
                                 default = nil)
  if valid_613192 != nil:
    section.add "X-Amz-Date", valid_613192
  var valid_613193 = header.getOrDefault("X-Amz-Credential")
  valid_613193 = validateParameter(valid_613193, JString, required = false,
                                 default = nil)
  if valid_613193 != nil:
    section.add "X-Amz-Credential", valid_613193
  var valid_613194 = header.getOrDefault("X-Amz-Security-Token")
  valid_613194 = validateParameter(valid_613194, JString, required = false,
                                 default = nil)
  if valid_613194 != nil:
    section.add "X-Amz-Security-Token", valid_613194
  var valid_613195 = header.getOrDefault("X-Amz-Algorithm")
  valid_613195 = validateParameter(valid_613195, JString, required = false,
                                 default = nil)
  if valid_613195 != nil:
    section.add "X-Amz-Algorithm", valid_613195
  var valid_613196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613196 = validateParameter(valid_613196, JString, required = false,
                                 default = nil)
  if valid_613196 != nil:
    section.add "X-Amz-SignedHeaders", valid_613196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613198: Call_UpdateUsage_613185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_613198.validator(path, query, header, formData, body)
  let scheme = call_613198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613198.url(scheme.get, call_613198.host, call_613198.base,
                         call_613198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613198, url, valid)

proc call*(call_613199: Call_UpdateUsage_613185; usageplanId: string; keyId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   body: JObject (required)
  var path_613200 = newJObject()
  var body_613201 = newJObject()
  add(path_613200, "usageplanId", newJString(usageplanId))
  add(path_613200, "keyId", newJString(keyId))
  if body != nil:
    body_613201 = body
  result = call_613199.call(path_613200, nil, nil, nil, body_613201)

var updateUsage* = Call_UpdateUsage_613185(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_613186,
                                        base: "/", url: url_UpdateUsage_613187,
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
