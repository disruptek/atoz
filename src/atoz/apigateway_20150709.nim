
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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
  Call_CreateApiKey_606171 = ref object of OpenApiRestCall_605573
proc url_CreateApiKey_606173(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiKey_606172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606174 = header.getOrDefault("X-Amz-Signature")
  valid_606174 = validateParameter(valid_606174, JString, required = false,
                                 default = nil)
  if valid_606174 != nil:
    section.add "X-Amz-Signature", valid_606174
  var valid_606175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606175 = validateParameter(valid_606175, JString, required = false,
                                 default = nil)
  if valid_606175 != nil:
    section.add "X-Amz-Content-Sha256", valid_606175
  var valid_606176 = header.getOrDefault("X-Amz-Date")
  valid_606176 = validateParameter(valid_606176, JString, required = false,
                                 default = nil)
  if valid_606176 != nil:
    section.add "X-Amz-Date", valid_606176
  var valid_606177 = header.getOrDefault("X-Amz-Credential")
  valid_606177 = validateParameter(valid_606177, JString, required = false,
                                 default = nil)
  if valid_606177 != nil:
    section.add "X-Amz-Credential", valid_606177
  var valid_606178 = header.getOrDefault("X-Amz-Security-Token")
  valid_606178 = validateParameter(valid_606178, JString, required = false,
                                 default = nil)
  if valid_606178 != nil:
    section.add "X-Amz-Security-Token", valid_606178
  var valid_606179 = header.getOrDefault("X-Amz-Algorithm")
  valid_606179 = validateParameter(valid_606179, JString, required = false,
                                 default = nil)
  if valid_606179 != nil:
    section.add "X-Amz-Algorithm", valid_606179
  var valid_606180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606180 = validateParameter(valid_606180, JString, required = false,
                                 default = nil)
  if valid_606180 != nil:
    section.add "X-Amz-SignedHeaders", valid_606180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606182: Call_CreateApiKey_606171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_606182.validator(path, query, header, formData, body)
  let scheme = call_606182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606182.url(scheme.get, call_606182.host, call_606182.base,
                         call_606182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606182, url, valid)

proc call*(call_606183: Call_CreateApiKey_606171; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_606184 = newJObject()
  if body != nil:
    body_606184 = body
  result = call_606183.call(nil, nil, nil, nil, body_606184)

var createApiKey* = Call_CreateApiKey_606171(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_606172, base: "/", url: url_CreateApiKey_606173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_605911 = ref object of OpenApiRestCall_605573
proc url_GetApiKeys_605913(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKeys_605912(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606025 = query.getOrDefault("name")
  valid_606025 = validateParameter(valid_606025, JString, required = false,
                                 default = nil)
  if valid_606025 != nil:
    section.add "name", valid_606025
  var valid_606026 = query.getOrDefault("limit")
  valid_606026 = validateParameter(valid_606026, JInt, required = false, default = nil)
  if valid_606026 != nil:
    section.add "limit", valid_606026
  var valid_606027 = query.getOrDefault("position")
  valid_606027 = validateParameter(valid_606027, JString, required = false,
                                 default = nil)
  if valid_606027 != nil:
    section.add "position", valid_606027
  var valid_606028 = query.getOrDefault("includeValues")
  valid_606028 = validateParameter(valid_606028, JBool, required = false, default = nil)
  if valid_606028 != nil:
    section.add "includeValues", valid_606028
  var valid_606029 = query.getOrDefault("customerId")
  valid_606029 = validateParameter(valid_606029, JString, required = false,
                                 default = nil)
  if valid_606029 != nil:
    section.add "customerId", valid_606029
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606030 = header.getOrDefault("X-Amz-Signature")
  valid_606030 = validateParameter(valid_606030, JString, required = false,
                                 default = nil)
  if valid_606030 != nil:
    section.add "X-Amz-Signature", valid_606030
  var valid_606031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606031 = validateParameter(valid_606031, JString, required = false,
                                 default = nil)
  if valid_606031 != nil:
    section.add "X-Amz-Content-Sha256", valid_606031
  var valid_606032 = header.getOrDefault("X-Amz-Date")
  valid_606032 = validateParameter(valid_606032, JString, required = false,
                                 default = nil)
  if valid_606032 != nil:
    section.add "X-Amz-Date", valid_606032
  var valid_606033 = header.getOrDefault("X-Amz-Credential")
  valid_606033 = validateParameter(valid_606033, JString, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "X-Amz-Credential", valid_606033
  var valid_606034 = header.getOrDefault("X-Amz-Security-Token")
  valid_606034 = validateParameter(valid_606034, JString, required = false,
                                 default = nil)
  if valid_606034 != nil:
    section.add "X-Amz-Security-Token", valid_606034
  var valid_606035 = header.getOrDefault("X-Amz-Algorithm")
  valid_606035 = validateParameter(valid_606035, JString, required = false,
                                 default = nil)
  if valid_606035 != nil:
    section.add "X-Amz-Algorithm", valid_606035
  var valid_606036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606036 = validateParameter(valid_606036, JString, required = false,
                                 default = nil)
  if valid_606036 != nil:
    section.add "X-Amz-SignedHeaders", valid_606036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606059: Call_GetApiKeys_605911; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_606059.validator(path, query, header, formData, body)
  let scheme = call_606059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606059.url(scheme.get, call_606059.host, call_606059.base,
                         call_606059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606059, url, valid)

proc call*(call_606130: Call_GetApiKeys_605911; name: string = ""; limit: int = 0;
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
  var query_606131 = newJObject()
  add(query_606131, "name", newJString(name))
  add(query_606131, "limit", newJInt(limit))
  add(query_606131, "position", newJString(position))
  add(query_606131, "includeValues", newJBool(includeValues))
  add(query_606131, "customerId", newJString(customerId))
  result = call_606130.call(nil, query_606131, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_605911(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_605912,
                                      base: "/", url: url_GetApiKeys_605913,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_606216 = ref object of OpenApiRestCall_605573
proc url_CreateAuthorizer_606218(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_606217(path: JsonNode; query: JsonNode;
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
  var valid_606219 = path.getOrDefault("restapi_id")
  valid_606219 = validateParameter(valid_606219, JString, required = true,
                                 default = nil)
  if valid_606219 != nil:
    section.add "restapi_id", valid_606219
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606220 = header.getOrDefault("X-Amz-Signature")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Signature", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Content-Sha256", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Date")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Date", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Credential")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Credential", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Security-Token")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Security-Token", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Algorithm")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Algorithm", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-SignedHeaders", valid_606226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606228: Call_CreateAuthorizer_606216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_606228.validator(path, query, header, formData, body)
  let scheme = call_606228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606228.url(scheme.get, call_606228.host, call_606228.base,
                         call_606228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606228, url, valid)

proc call*(call_606229: Call_CreateAuthorizer_606216; restapiId: string;
          body: JsonNode): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606230 = newJObject()
  var body_606231 = newJObject()
  add(path_606230, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606231 = body
  result = call_606229.call(path_606230, nil, nil, nil, body_606231)

var createAuthorizer* = Call_CreateAuthorizer_606216(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_606217, base: "/",
    url: url_CreateAuthorizer_606218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_606185 = ref object of OpenApiRestCall_605573
proc url_GetAuthorizers_606187(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_606186(path: JsonNode; query: JsonNode;
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
  var valid_606202 = path.getOrDefault("restapi_id")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "restapi_id", valid_606202
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_606203 = query.getOrDefault("limit")
  valid_606203 = validateParameter(valid_606203, JInt, required = false, default = nil)
  if valid_606203 != nil:
    section.add "limit", valid_606203
  var valid_606204 = query.getOrDefault("position")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "position", valid_606204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606205 = header.getOrDefault("X-Amz-Signature")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Signature", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Content-Sha256", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Date")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Date", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Credential")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Credential", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Security-Token")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Security-Token", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Algorithm")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Algorithm", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-SignedHeaders", valid_606211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606212: Call_GetAuthorizers_606185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_606212.validator(path, query, header, formData, body)
  let scheme = call_606212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606212.url(scheme.get, call_606212.host, call_606212.base,
                         call_606212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606212, url, valid)

proc call*(call_606213: Call_GetAuthorizers_606185; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606214 = newJObject()
  var query_606215 = newJObject()
  add(query_606215, "limit", newJInt(limit))
  add(query_606215, "position", newJString(position))
  add(path_606214, "restapi_id", newJString(restapiId))
  result = call_606213.call(path_606214, query_606215, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_606185(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_606186, base: "/", url: url_GetAuthorizers_606187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_606249 = ref object of OpenApiRestCall_605573
proc url_CreateBasePathMapping_606251(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBasePathMapping_606250(path: JsonNode; query: JsonNode;
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
  var valid_606252 = path.getOrDefault("domain_name")
  valid_606252 = validateParameter(valid_606252, JString, required = true,
                                 default = nil)
  if valid_606252 != nil:
    section.add "domain_name", valid_606252
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606253 = header.getOrDefault("X-Amz-Signature")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Signature", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Content-Sha256", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Date")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Date", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Credential")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Credential", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Security-Token")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Security-Token", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Algorithm")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Algorithm", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-SignedHeaders", valid_606259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606261: Call_CreateBasePathMapping_606249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_606261.validator(path, query, header, formData, body)
  let scheme = call_606261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606261.url(scheme.get, call_606261.host, call_606261.base,
                         call_606261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606261, url, valid)

proc call*(call_606262: Call_CreateBasePathMapping_606249; body: JsonNode;
          domainName: string): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  var path_606263 = newJObject()
  var body_606264 = newJObject()
  if body != nil:
    body_606264 = body
  add(path_606263, "domain_name", newJString(domainName))
  result = call_606262.call(path_606263, nil, nil, nil, body_606264)

var createBasePathMapping* = Call_CreateBasePathMapping_606249(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_606250, base: "/",
    url: url_CreateBasePathMapping_606251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_606232 = ref object of OpenApiRestCall_605573
proc url_GetBasePathMappings_606234(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMappings_606233(path: JsonNode; query: JsonNode;
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
  var valid_606235 = path.getOrDefault("domain_name")
  valid_606235 = validateParameter(valid_606235, JString, required = true,
                                 default = nil)
  if valid_606235 != nil:
    section.add "domain_name", valid_606235
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_606236 = query.getOrDefault("limit")
  valid_606236 = validateParameter(valid_606236, JInt, required = false, default = nil)
  if valid_606236 != nil:
    section.add "limit", valid_606236
  var valid_606237 = query.getOrDefault("position")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "position", valid_606237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606238 = header.getOrDefault("X-Amz-Signature")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Signature", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Content-Sha256", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Date")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Date", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Credential")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Credential", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Security-Token")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Security-Token", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Algorithm")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Algorithm", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-SignedHeaders", valid_606244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606245: Call_GetBasePathMappings_606232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_606245.validator(path, query, header, formData, body)
  let scheme = call_606245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606245.url(scheme.get, call_606245.host, call_606245.base,
                         call_606245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606245, url, valid)

proc call*(call_606246: Call_GetBasePathMappings_606232; domainName: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  var path_606247 = newJObject()
  var query_606248 = newJObject()
  add(query_606248, "limit", newJInt(limit))
  add(query_606248, "position", newJString(position))
  add(path_606247, "domain_name", newJString(domainName))
  result = call_606246.call(path_606247, query_606248, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_606232(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_606233, base: "/",
    url: url_GetBasePathMappings_606234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_606282 = ref object of OpenApiRestCall_605573
proc url_CreateDeployment_606284(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_606283(path: JsonNode; query: JsonNode;
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
  var valid_606285 = path.getOrDefault("restapi_id")
  valid_606285 = validateParameter(valid_606285, JString, required = true,
                                 default = nil)
  if valid_606285 != nil:
    section.add "restapi_id", valid_606285
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606286 = header.getOrDefault("X-Amz-Signature")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Signature", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Content-Sha256", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Date")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Date", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Credential")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Credential", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Security-Token")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Security-Token", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Algorithm")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Algorithm", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-SignedHeaders", valid_606292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606294: Call_CreateDeployment_606282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_606294.validator(path, query, header, formData, body)
  let scheme = call_606294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606294.url(scheme.get, call_606294.host, call_606294.base,
                         call_606294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606294, url, valid)

proc call*(call_606295: Call_CreateDeployment_606282; restapiId: string;
          body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606296 = newJObject()
  var body_606297 = newJObject()
  add(path_606296, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606297 = body
  result = call_606295.call(path_606296, nil, nil, nil, body_606297)

var createDeployment* = Call_CreateDeployment_606282(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_606283, base: "/",
    url: url_CreateDeployment_606284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_606265 = ref object of OpenApiRestCall_605573
proc url_GetDeployments_606267(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_606266(path: JsonNode; query: JsonNode;
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
  var valid_606268 = path.getOrDefault("restapi_id")
  valid_606268 = validateParameter(valid_606268, JString, required = true,
                                 default = nil)
  if valid_606268 != nil:
    section.add "restapi_id", valid_606268
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_606269 = query.getOrDefault("limit")
  valid_606269 = validateParameter(valid_606269, JInt, required = false, default = nil)
  if valid_606269 != nil:
    section.add "limit", valid_606269
  var valid_606270 = query.getOrDefault("position")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "position", valid_606270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606271 = header.getOrDefault("X-Amz-Signature")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Signature", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Content-Sha256", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Date")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Date", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Credential")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Credential", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Security-Token")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Security-Token", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Algorithm")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Algorithm", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-SignedHeaders", valid_606277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606278: Call_GetDeployments_606265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_606278.validator(path, query, header, formData, body)
  let scheme = call_606278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606278.url(scheme.get, call_606278.host, call_606278.base,
                         call_606278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606278, url, valid)

proc call*(call_606279: Call_GetDeployments_606265; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606280 = newJObject()
  var query_606281 = newJObject()
  add(query_606281, "limit", newJInt(limit))
  add(query_606281, "position", newJString(position))
  add(path_606280, "restapi_id", newJString(restapiId))
  result = call_606279.call(path_606280, query_606281, nil, nil, nil)

var getDeployments* = Call_GetDeployments_606265(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_606266, base: "/", url: url_GetDeployments_606267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_606332 = ref object of OpenApiRestCall_605573
proc url_ImportDocumentationParts_606334(protocol: Scheme; host: string;
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

proc validate_ImportDocumentationParts_606333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_606335 = path.getOrDefault("restapi_id")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = nil)
  if valid_606335 != nil:
    section.add "restapi_id", valid_606335
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  section = newJObject()
  var valid_606336 = query.getOrDefault("failonwarnings")
  valid_606336 = validateParameter(valid_606336, JBool, required = false, default = nil)
  if valid_606336 != nil:
    section.add "failonwarnings", valid_606336
  var valid_606337 = query.getOrDefault("mode")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = newJString("merge"))
  if valid_606337 != nil:
    section.add "mode", valid_606337
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606338 = header.getOrDefault("X-Amz-Signature")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Signature", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Content-Sha256", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Date")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Date", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Credential")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Credential", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Security-Token")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Security-Token", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Algorithm")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Algorithm", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-SignedHeaders", valid_606344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606346: Call_ImportDocumentationParts_606332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606346.validator(path, query, header, formData, body)
  let scheme = call_606346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606346.url(scheme.get, call_606346.host, call_606346.base,
                         call_606346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606346, url, valid)

proc call*(call_606347: Call_ImportDocumentationParts_606332; restapiId: string;
          body: JsonNode; failonwarnings: bool = false; mode: string = "merge"): Recallable =
  ## importDocumentationParts
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606348 = newJObject()
  var query_606349 = newJObject()
  var body_606350 = newJObject()
  add(query_606349, "failonwarnings", newJBool(failonwarnings))
  add(query_606349, "mode", newJString(mode))
  add(path_606348, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606350 = body
  result = call_606347.call(path_606348, query_606349, nil, nil, body_606350)

var importDocumentationParts* = Call_ImportDocumentationParts_606332(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_606333, base: "/",
    url: url_ImportDocumentationParts_606334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_606351 = ref object of OpenApiRestCall_605573
proc url_CreateDocumentationPart_606353(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocumentationPart_606352(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_606354 = path.getOrDefault("restapi_id")
  valid_606354 = validateParameter(valid_606354, JString, required = true,
                                 default = nil)
  if valid_606354 != nil:
    section.add "restapi_id", valid_606354
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606355 = header.getOrDefault("X-Amz-Signature")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Signature", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Content-Sha256", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Date")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Date", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Credential")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Credential", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Security-Token")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Security-Token", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Algorithm")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Algorithm", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-SignedHeaders", valid_606361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606363: Call_CreateDocumentationPart_606351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606363.validator(path, query, header, formData, body)
  let scheme = call_606363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606363.url(scheme.get, call_606363.host, call_606363.base,
                         call_606363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606363, url, valid)

proc call*(call_606364: Call_CreateDocumentationPart_606351; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationPart
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606365 = newJObject()
  var body_606366 = newJObject()
  add(path_606365, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606366 = body
  result = call_606364.call(path_606365, nil, nil, nil, body_606366)

var createDocumentationPart* = Call_CreateDocumentationPart_606351(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_606352, base: "/",
    url: url_CreateDocumentationPart_606353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_606298 = ref object of OpenApiRestCall_605573
proc url_GetDocumentationParts_606300(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationParts_606299(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_606301 = path.getOrDefault("restapi_id")
  valid_606301 = validateParameter(valid_606301, JString, required = true,
                                 default = nil)
  if valid_606301 != nil:
    section.add "restapi_id", valid_606301
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
  var valid_606302 = query.getOrDefault("name")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "name", valid_606302
  var valid_606303 = query.getOrDefault("limit")
  valid_606303 = validateParameter(valid_606303, JInt, required = false, default = nil)
  if valid_606303 != nil:
    section.add "limit", valid_606303
  var valid_606317 = query.getOrDefault("locationStatus")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_606317 != nil:
    section.add "locationStatus", valid_606317
  var valid_606318 = query.getOrDefault("path")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "path", valid_606318
  var valid_606319 = query.getOrDefault("position")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "position", valid_606319
  var valid_606320 = query.getOrDefault("type")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = newJString("API"))
  if valid_606320 != nil:
    section.add "type", valid_606320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606321 = header.getOrDefault("X-Amz-Signature")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Signature", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Content-Sha256", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Date")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Date", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Credential")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Credential", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Security-Token")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Security-Token", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Algorithm")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Algorithm", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-SignedHeaders", valid_606327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_GetDocumentationParts_606298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_GetDocumentationParts_606298; restapiId: string;
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
  var path_606330 = newJObject()
  var query_606331 = newJObject()
  add(query_606331, "name", newJString(name))
  add(query_606331, "limit", newJInt(limit))
  add(query_606331, "locationStatus", newJString(locationStatus))
  add(query_606331, "path", newJString(path))
  add(query_606331, "position", newJString(position))
  add(query_606331, "type", newJString(`type`))
  add(path_606330, "restapi_id", newJString(restapiId))
  result = call_606329.call(path_606330, query_606331, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_606298(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_606299, base: "/",
    url: url_GetDocumentationParts_606300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_606384 = ref object of OpenApiRestCall_605573
proc url_CreateDocumentationVersion_606386(protocol: Scheme; host: string;
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

proc validate_CreateDocumentationVersion_606385(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_606387 = path.getOrDefault("restapi_id")
  valid_606387 = validateParameter(valid_606387, JString, required = true,
                                 default = nil)
  if valid_606387 != nil:
    section.add "restapi_id", valid_606387
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606388 = header.getOrDefault("X-Amz-Signature")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Signature", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Content-Sha256", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Date")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Date", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Credential")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Credential", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Security-Token")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Security-Token", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Algorithm")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Algorithm", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-SignedHeaders", valid_606394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606396: Call_CreateDocumentationVersion_606384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606396.validator(path, query, header, formData, body)
  let scheme = call_606396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606396.url(scheme.get, call_606396.host, call_606396.base,
                         call_606396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606396, url, valid)

proc call*(call_606397: Call_CreateDocumentationVersion_606384; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationVersion
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606398 = newJObject()
  var body_606399 = newJObject()
  add(path_606398, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606399 = body
  result = call_606397.call(path_606398, nil, nil, nil, body_606399)

var createDocumentationVersion* = Call_CreateDocumentationVersion_606384(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_606385, base: "/",
    url: url_CreateDocumentationVersion_606386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_606367 = ref object of OpenApiRestCall_605573
proc url_GetDocumentationVersions_606369(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersions_606368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_606370 = path.getOrDefault("restapi_id")
  valid_606370 = validateParameter(valid_606370, JString, required = true,
                                 default = nil)
  if valid_606370 != nil:
    section.add "restapi_id", valid_606370
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_606371 = query.getOrDefault("limit")
  valid_606371 = validateParameter(valid_606371, JInt, required = false, default = nil)
  if valid_606371 != nil:
    section.add "limit", valid_606371
  var valid_606372 = query.getOrDefault("position")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "position", valid_606372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606373 = header.getOrDefault("X-Amz-Signature")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Signature", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Content-Sha256", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Date")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Date", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Credential")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Credential", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Security-Token")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Security-Token", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Algorithm")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Algorithm", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-SignedHeaders", valid_606379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606380: Call_GetDocumentationVersions_606367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606380.validator(path, query, header, formData, body)
  let scheme = call_606380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606380.url(scheme.get, call_606380.host, call_606380.base,
                         call_606380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606380, url, valid)

proc call*(call_606381: Call_GetDocumentationVersions_606367; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDocumentationVersions
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606382 = newJObject()
  var query_606383 = newJObject()
  add(query_606383, "limit", newJInt(limit))
  add(query_606383, "position", newJString(position))
  add(path_606382, "restapi_id", newJString(restapiId))
  result = call_606381.call(path_606382, query_606383, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_606367(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_606368, base: "/",
    url: url_GetDocumentationVersions_606369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_606415 = ref object of OpenApiRestCall_605573
proc url_CreateDomainName_606417(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainName_606416(path: JsonNode; query: JsonNode;
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
  var valid_606418 = header.getOrDefault("X-Amz-Signature")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Signature", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Content-Sha256", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Date")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Date", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Credential")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Credential", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Security-Token")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Security-Token", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Algorithm")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Algorithm", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-SignedHeaders", valid_606424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606426: Call_CreateDomainName_606415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_606426.validator(path, query, header, formData, body)
  let scheme = call_606426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606426.url(scheme.get, call_606426.host, call_606426.base,
                         call_606426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606426, url, valid)

proc call*(call_606427: Call_CreateDomainName_606415; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_606428 = newJObject()
  if body != nil:
    body_606428 = body
  result = call_606427.call(nil, nil, nil, nil, body_606428)

var createDomainName* = Call_CreateDomainName_606415(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_606416, base: "/",
    url: url_CreateDomainName_606417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_606400 = ref object of OpenApiRestCall_605573
proc url_GetDomainNames_606402(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainNames_606401(path: JsonNode; query: JsonNode;
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
  var valid_606403 = query.getOrDefault("limit")
  valid_606403 = validateParameter(valid_606403, JInt, required = false, default = nil)
  if valid_606403 != nil:
    section.add "limit", valid_606403
  var valid_606404 = query.getOrDefault("position")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "position", valid_606404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606405 = header.getOrDefault("X-Amz-Signature")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Signature", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Content-Sha256", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Date")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Date", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Credential")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Credential", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Security-Token")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Security-Token", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Algorithm")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Algorithm", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-SignedHeaders", valid_606411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606412: Call_GetDomainNames_606400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_606412.validator(path, query, header, formData, body)
  let scheme = call_606412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606412.url(scheme.get, call_606412.host, call_606412.base,
                         call_606412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606412, url, valid)

proc call*(call_606413: Call_GetDomainNames_606400; limit: int = 0;
          position: string = ""): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_606414 = newJObject()
  add(query_606414, "limit", newJInt(limit))
  add(query_606414, "position", newJString(position))
  result = call_606413.call(nil, query_606414, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_606400(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_606401, base: "/",
    url: url_GetDomainNames_606402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_606446 = ref object of OpenApiRestCall_605573
proc url_CreateModel_606448(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_606447(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606449 = path.getOrDefault("restapi_id")
  valid_606449 = validateParameter(valid_606449, JString, required = true,
                                 default = nil)
  if valid_606449 != nil:
    section.add "restapi_id", valid_606449
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606450 = header.getOrDefault("X-Amz-Signature")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Signature", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Content-Sha256", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Date")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Date", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Credential")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Credential", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Security-Token")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Security-Token", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Algorithm")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Algorithm", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-SignedHeaders", valid_606456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606458: Call_CreateModel_606446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_606458.validator(path, query, header, formData, body)
  let scheme = call_606458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606458.url(scheme.get, call_606458.host, call_606458.base,
                         call_606458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606458, url, valid)

proc call*(call_606459: Call_CreateModel_606446; restapiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  ##   body: JObject (required)
  var path_606460 = newJObject()
  var body_606461 = newJObject()
  add(path_606460, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606461 = body
  result = call_606459.call(path_606460, nil, nil, nil, body_606461)

var createModel* = Call_CreateModel_606446(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_606447,
                                        base: "/", url: url_CreateModel_606448,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_606429 = ref object of OpenApiRestCall_605573
proc url_GetModels_606431(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_606430(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606432 = path.getOrDefault("restapi_id")
  valid_606432 = validateParameter(valid_606432, JString, required = true,
                                 default = nil)
  if valid_606432 != nil:
    section.add "restapi_id", valid_606432
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_606433 = query.getOrDefault("limit")
  valid_606433 = validateParameter(valid_606433, JInt, required = false, default = nil)
  if valid_606433 != nil:
    section.add "limit", valid_606433
  var valid_606434 = query.getOrDefault("position")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "position", valid_606434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606435 = header.getOrDefault("X-Amz-Signature")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Signature", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Content-Sha256", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Date")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Date", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Credential")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Credential", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Security-Token")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Security-Token", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Algorithm")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Algorithm", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-SignedHeaders", valid_606441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606442: Call_GetModels_606429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_606442.validator(path, query, header, formData, body)
  let scheme = call_606442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606442.url(scheme.get, call_606442.host, call_606442.base,
                         call_606442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606442, url, valid)

proc call*(call_606443: Call_GetModels_606429; restapiId: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606444 = newJObject()
  var query_606445 = newJObject()
  add(query_606445, "limit", newJInt(limit))
  add(query_606445, "position", newJString(position))
  add(path_606444, "restapi_id", newJString(restapiId))
  result = call_606443.call(path_606444, query_606445, nil, nil, nil)

var getModels* = Call_GetModels_606429(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_606430,
                                    base: "/", url: url_GetModels_606431,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_606479 = ref object of OpenApiRestCall_605573
proc url_CreateRequestValidator_606481(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRequestValidator_606480(path: JsonNode; query: JsonNode;
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
  var valid_606482 = path.getOrDefault("restapi_id")
  valid_606482 = validateParameter(valid_606482, JString, required = true,
                                 default = nil)
  if valid_606482 != nil:
    section.add "restapi_id", valid_606482
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606483 = header.getOrDefault("X-Amz-Signature")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Signature", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Content-Sha256", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Date")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Date", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Credential")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Credential", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Security-Token")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Security-Token", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Algorithm")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Algorithm", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-SignedHeaders", valid_606489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606491: Call_CreateRequestValidator_606479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_606491.validator(path, query, header, formData, body)
  let scheme = call_606491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606491.url(scheme.get, call_606491.host, call_606491.base,
                         call_606491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606491, url, valid)

proc call*(call_606492: Call_CreateRequestValidator_606479; restapiId: string;
          body: JsonNode): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606493 = newJObject()
  var body_606494 = newJObject()
  add(path_606493, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606494 = body
  result = call_606492.call(path_606493, nil, nil, nil, body_606494)

var createRequestValidator* = Call_CreateRequestValidator_606479(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_606480, base: "/",
    url: url_CreateRequestValidator_606481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_606462 = ref object of OpenApiRestCall_605573
proc url_GetRequestValidators_606464(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidators_606463(path: JsonNode; query: JsonNode;
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
  var valid_606465 = path.getOrDefault("restapi_id")
  valid_606465 = validateParameter(valid_606465, JString, required = true,
                                 default = nil)
  if valid_606465 != nil:
    section.add "restapi_id", valid_606465
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_606466 = query.getOrDefault("limit")
  valid_606466 = validateParameter(valid_606466, JInt, required = false, default = nil)
  if valid_606466 != nil:
    section.add "limit", valid_606466
  var valid_606467 = query.getOrDefault("position")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "position", valid_606467
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606468 = header.getOrDefault("X-Amz-Signature")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Signature", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Content-Sha256", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Date")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Date", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Credential")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Credential", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Security-Token")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Security-Token", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Algorithm")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Algorithm", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-SignedHeaders", valid_606474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606475: Call_GetRequestValidators_606462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_606475.validator(path, query, header, formData, body)
  let scheme = call_606475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606475.url(scheme.get, call_606475.host, call_606475.base,
                         call_606475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606475, url, valid)

proc call*(call_606476: Call_GetRequestValidators_606462; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606477 = newJObject()
  var query_606478 = newJObject()
  add(query_606478, "limit", newJInt(limit))
  add(query_606478, "position", newJString(position))
  add(path_606477, "restapi_id", newJString(restapiId))
  result = call_606476.call(path_606477, query_606478, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_606462(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_606463, base: "/",
    url: url_GetRequestValidators_606464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_606495 = ref object of OpenApiRestCall_605573
proc url_CreateResource_606497(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResource_606496(path: JsonNode; query: JsonNode;
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
  var valid_606498 = path.getOrDefault("restapi_id")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = nil)
  if valid_606498 != nil:
    section.add "restapi_id", valid_606498
  var valid_606499 = path.getOrDefault("parent_id")
  valid_606499 = validateParameter(valid_606499, JString, required = true,
                                 default = nil)
  if valid_606499 != nil:
    section.add "parent_id", valid_606499
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_CreateResource_606495; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_CreateResource_606495; restapiId: string;
          body: JsonNode; parentId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  var path_606510 = newJObject()
  var body_606511 = newJObject()
  add(path_606510, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606511 = body
  add(path_606510, "parent_id", newJString(parentId))
  result = call_606509.call(path_606510, nil, nil, nil, body_606511)

var createResource* = Call_CreateResource_606495(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_606496, base: "/", url: url_CreateResource_606497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_606527 = ref object of OpenApiRestCall_605573
proc url_CreateRestApi_606529(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRestApi_606528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_CreateRestApi_606527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_CreateRestApi_606527; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var createRestApi* = Call_CreateRestApi_606527(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_606528, base: "/", url: url_CreateRestApi_606529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_606512 = ref object of OpenApiRestCall_605573
proc url_GetRestApis_606514(protocol: Scheme; host: string; base: string;
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

proc validate_GetRestApis_606513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606515 = query.getOrDefault("limit")
  valid_606515 = validateParameter(valid_606515, JInt, required = false, default = nil)
  if valid_606515 != nil:
    section.add "limit", valid_606515
  var valid_606516 = query.getOrDefault("position")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "position", valid_606516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606517 = header.getOrDefault("X-Amz-Signature")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Signature", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Content-Sha256", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Date")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Date", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Credential")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Credential", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Security-Token")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Security-Token", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Algorithm")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Algorithm", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-SignedHeaders", valid_606523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606524: Call_GetRestApis_606512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_606524.validator(path, query, header, formData, body)
  let scheme = call_606524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606524.url(scheme.get, call_606524.host, call_606524.base,
                         call_606524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606524, url, valid)

proc call*(call_606525: Call_GetRestApis_606512; limit: int = 0; position: string = ""): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_606526 = newJObject()
  add(query_606526, "limit", newJInt(limit))
  add(query_606526, "position", newJString(position))
  result = call_606525.call(nil, query_606526, nil, nil, nil)

var getRestApis* = Call_GetRestApis_606512(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_606513,
                                        base: "/", url: url_GetRestApis_606514,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_606557 = ref object of OpenApiRestCall_605573
proc url_CreateStage_606559(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_606558(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606560 = path.getOrDefault("restapi_id")
  valid_606560 = validateParameter(valid_606560, JString, required = true,
                                 default = nil)
  if valid_606560 != nil:
    section.add "restapi_id", valid_606560
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606561 = header.getOrDefault("X-Amz-Signature")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Signature", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Content-Sha256", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Date")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Date", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Credential")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Credential", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Security-Token")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Security-Token", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Algorithm")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Algorithm", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-SignedHeaders", valid_606567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606569: Call_CreateStage_606557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_606569.validator(path, query, header, formData, body)
  let scheme = call_606569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606569.url(scheme.get, call_606569.host, call_606569.base,
                         call_606569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606569, url, valid)

proc call*(call_606570: Call_CreateStage_606557; restapiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606571 = newJObject()
  var body_606572 = newJObject()
  add(path_606571, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606572 = body
  result = call_606570.call(path_606571, nil, nil, nil, body_606572)

var createStage* = Call_CreateStage_606557(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_606558,
                                        base: "/", url: url_CreateStage_606559,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_606541 = ref object of OpenApiRestCall_605573
proc url_GetStages_606543(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_606542(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606544 = path.getOrDefault("restapi_id")
  valid_606544 = validateParameter(valid_606544, JString, required = true,
                                 default = nil)
  if valid_606544 != nil:
    section.add "restapi_id", valid_606544
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_606545 = query.getOrDefault("deploymentId")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "deploymentId", valid_606545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606546 = header.getOrDefault("X-Amz-Signature")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Signature", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Content-Sha256", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Date")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Date", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Credential")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Credential", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Security-Token")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Security-Token", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Algorithm")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Algorithm", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-SignedHeaders", valid_606552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_GetStages_606541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_GetStages_606541; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  var path_606555 = newJObject()
  var query_606556 = newJObject()
  add(path_606555, "restapi_id", newJString(restapiId))
  add(query_606556, "deploymentId", newJString(deploymentId))
  result = call_606554.call(path_606555, query_606556, nil, nil, nil)

var getStages* = Call_GetStages_606541(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_606542,
                                    base: "/", url: url_GetStages_606543,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_606589 = ref object of OpenApiRestCall_605573
proc url_CreateUsagePlan_606591(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlan_606590(path: JsonNode; query: JsonNode;
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
  var valid_606592 = header.getOrDefault("X-Amz-Signature")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Signature", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Content-Sha256", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Date")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Date", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Credential")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Credential", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Security-Token")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Security-Token", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Algorithm")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Algorithm", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-SignedHeaders", valid_606598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606600: Call_CreateUsagePlan_606589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_606600.validator(path, query, header, formData, body)
  let scheme = call_606600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606600.url(scheme.get, call_606600.host, call_606600.base,
                         call_606600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606600, url, valid)

proc call*(call_606601: Call_CreateUsagePlan_606589; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_606602 = newJObject()
  if body != nil:
    body_606602 = body
  result = call_606601.call(nil, nil, nil, nil, body_606602)

var createUsagePlan* = Call_CreateUsagePlan_606589(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_606590, base: "/",
    url: url_CreateUsagePlan_606591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_606573 = ref object of OpenApiRestCall_605573
proc url_GetUsagePlans_606575(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlans_606574(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606576 = query.getOrDefault("limit")
  valid_606576 = validateParameter(valid_606576, JInt, required = false, default = nil)
  if valid_606576 != nil:
    section.add "limit", valid_606576
  var valid_606577 = query.getOrDefault("position")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "position", valid_606577
  var valid_606578 = query.getOrDefault("keyId")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "keyId", valid_606578
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_606586: Call_GetUsagePlans_606573; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_606586.validator(path, query, header, formData, body)
  let scheme = call_606586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606586.url(scheme.get, call_606586.host, call_606586.base,
                         call_606586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606586, url, valid)

proc call*(call_606587: Call_GetUsagePlans_606573; limit: int = 0;
          position: string = ""; keyId: string = ""): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  var query_606588 = newJObject()
  add(query_606588, "limit", newJInt(limit))
  add(query_606588, "position", newJString(position))
  add(query_606588, "keyId", newJString(keyId))
  result = call_606587.call(nil, query_606588, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_606573(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_606574, base: "/",
    url: url_GetUsagePlans_606575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_606621 = ref object of OpenApiRestCall_605573
proc url_CreateUsagePlanKey_606623(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlanKey_606622(path: JsonNode; query: JsonNode;
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
  var valid_606624 = path.getOrDefault("usageplanId")
  valid_606624 = validateParameter(valid_606624, JString, required = true,
                                 default = nil)
  if valid_606624 != nil:
    section.add "usageplanId", valid_606624
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606625 = header.getOrDefault("X-Amz-Signature")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Signature", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Content-Sha256", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Date")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Date", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Credential")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Credential", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Security-Token")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Security-Token", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Algorithm")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Algorithm", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-SignedHeaders", valid_606631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606633: Call_CreateUsagePlanKey_606621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_606633.validator(path, query, header, formData, body)
  let scheme = call_606633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606633.url(scheme.get, call_606633.host, call_606633.base,
                         call_606633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606633, url, valid)

proc call*(call_606634: Call_CreateUsagePlanKey_606621; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_606635 = newJObject()
  var body_606636 = newJObject()
  add(path_606635, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_606636 = body
  result = call_606634.call(path_606635, nil, nil, nil, body_606636)

var createUsagePlanKey* = Call_CreateUsagePlanKey_606621(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_606622, base: "/",
    url: url_CreateUsagePlanKey_606623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_606603 = ref object of OpenApiRestCall_605573
proc url_GetUsagePlanKeys_606605(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKeys_606604(path: JsonNode; query: JsonNode;
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
  var valid_606606 = path.getOrDefault("usageplanId")
  valid_606606 = validateParameter(valid_606606, JString, required = true,
                                 default = nil)
  if valid_606606 != nil:
    section.add "usageplanId", valid_606606
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_606607 = query.getOrDefault("name")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "name", valid_606607
  var valid_606608 = query.getOrDefault("limit")
  valid_606608 = validateParameter(valid_606608, JInt, required = false, default = nil)
  if valid_606608 != nil:
    section.add "limit", valid_606608
  var valid_606609 = query.getOrDefault("position")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "position", valid_606609
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_606617: Call_GetUsagePlanKeys_606603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_606617.validator(path, query, header, formData, body)
  let scheme = call_606617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606617.url(scheme.get, call_606617.host, call_606617.base,
                         call_606617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606617, url, valid)

proc call*(call_606618: Call_GetUsagePlanKeys_606603; usageplanId: string;
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
  var path_606619 = newJObject()
  var query_606620 = newJObject()
  add(query_606620, "name", newJString(name))
  add(path_606619, "usageplanId", newJString(usageplanId))
  add(query_606620, "limit", newJInt(limit))
  add(query_606620, "position", newJString(position))
  result = call_606618.call(path_606619, query_606620, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_606603(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_606604,
    base: "/", url: url_GetUsagePlanKeys_606605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_606652 = ref object of OpenApiRestCall_605573
proc url_CreateVpcLink_606654(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVpcLink_606653(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606655 = header.getOrDefault("X-Amz-Signature")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Signature", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Content-Sha256", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Date")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Date", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Credential")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Credential", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Security-Token")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Security-Token", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Algorithm")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Algorithm", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-SignedHeaders", valid_606661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606663: Call_CreateVpcLink_606652; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_606663.validator(path, query, header, formData, body)
  let scheme = call_606663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606663.url(scheme.get, call_606663.host, call_606663.base,
                         call_606663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606663, url, valid)

proc call*(call_606664: Call_CreateVpcLink_606652; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_606665 = newJObject()
  if body != nil:
    body_606665 = body
  result = call_606664.call(nil, nil, nil, nil, body_606665)

var createVpcLink* = Call_CreateVpcLink_606652(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_606653, base: "/", url: url_CreateVpcLink_606654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_606637 = ref object of OpenApiRestCall_605573
proc url_GetVpcLinks_606639(protocol: Scheme; host: string; base: string;
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

proc validate_GetVpcLinks_606638(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606640 = query.getOrDefault("limit")
  valid_606640 = validateParameter(valid_606640, JInt, required = false, default = nil)
  if valid_606640 != nil:
    section.add "limit", valid_606640
  var valid_606641 = query.getOrDefault("position")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "position", valid_606641
  result.add "query", section
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

proc call*(call_606649: Call_GetVpcLinks_606637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_606649.validator(path, query, header, formData, body)
  let scheme = call_606649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606649.url(scheme.get, call_606649.host, call_606649.base,
                         call_606649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606649, url, valid)

proc call*(call_606650: Call_GetVpcLinks_606637; limit: int = 0; position: string = ""): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_606651 = newJObject()
  add(query_606651, "limit", newJInt(limit))
  add(query_606651, "position", newJString(position))
  result = call_606650.call(nil, query_606651, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_606637(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_606638,
                                        base: "/", url: url_GetVpcLinks_606639,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_606666 = ref object of OpenApiRestCall_605573
proc url_GetApiKey_606668(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKey_606667(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606669 = path.getOrDefault("api_Key")
  valid_606669 = validateParameter(valid_606669, JString, required = true,
                                 default = nil)
  if valid_606669 != nil:
    section.add "api_Key", valid_606669
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_606670 = query.getOrDefault("includeValue")
  valid_606670 = validateParameter(valid_606670, JBool, required = false, default = nil)
  if valid_606670 != nil:
    section.add "includeValue", valid_606670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606671 = header.getOrDefault("X-Amz-Signature")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Signature", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Content-Sha256", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Date")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Date", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Credential")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Credential", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Security-Token")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Security-Token", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Algorithm")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Algorithm", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-SignedHeaders", valid_606677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606678: Call_GetApiKey_606666; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_606678.validator(path, query, header, formData, body)
  let scheme = call_606678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606678.url(scheme.get, call_606678.host, call_606678.base,
                         call_606678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606678, url, valid)

proc call*(call_606679: Call_GetApiKey_606666; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_606680 = newJObject()
  var query_606681 = newJObject()
  add(query_606681, "includeValue", newJBool(includeValue))
  add(path_606680, "api_Key", newJString(apiKey))
  result = call_606679.call(path_606680, query_606681, nil, nil, nil)

var getApiKey* = Call_GetApiKey_606666(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_606667,
                                    base: "/", url: url_GetApiKey_606668,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_606696 = ref object of OpenApiRestCall_605573
proc url_UpdateApiKey_606698(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_606697(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606699 = path.getOrDefault("api_Key")
  valid_606699 = validateParameter(valid_606699, JString, required = true,
                                 default = nil)
  if valid_606699 != nil:
    section.add "api_Key", valid_606699
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606700 = header.getOrDefault("X-Amz-Signature")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Signature", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Content-Sha256", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Date")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Date", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Credential")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Credential", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Security-Token")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Security-Token", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Algorithm")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Algorithm", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-SignedHeaders", valid_606706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606708: Call_UpdateApiKey_606696; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_606708.validator(path, query, header, formData, body)
  let scheme = call_606708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606708.url(scheme.get, call_606708.host, call_606708.base,
                         call_606708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606708, url, valid)

proc call*(call_606709: Call_UpdateApiKey_606696; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_606710 = newJObject()
  var body_606711 = newJObject()
  add(path_606710, "api_Key", newJString(apiKey))
  if body != nil:
    body_606711 = body
  result = call_606709.call(path_606710, nil, nil, nil, body_606711)

var updateApiKey* = Call_UpdateApiKey_606696(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_606697, base: "/",
    url: url_UpdateApiKey_606698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_606682 = ref object of OpenApiRestCall_605573
proc url_DeleteApiKey_606684(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_606683(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606685 = path.getOrDefault("api_Key")
  valid_606685 = validateParameter(valid_606685, JString, required = true,
                                 default = nil)
  if valid_606685 != nil:
    section.add "api_Key", valid_606685
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606686 = header.getOrDefault("X-Amz-Signature")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Signature", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Content-Sha256", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Date")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Date", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Credential")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Credential", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Security-Token")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Security-Token", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Algorithm")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Algorithm", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-SignedHeaders", valid_606692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606693: Call_DeleteApiKey_606682; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_606693.validator(path, query, header, formData, body)
  let scheme = call_606693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606693.url(scheme.get, call_606693.host, call_606693.base,
                         call_606693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606693, url, valid)

proc call*(call_606694: Call_DeleteApiKey_606682; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_606695 = newJObject()
  add(path_606695, "api_Key", newJString(apiKey))
  result = call_606694.call(path_606695, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_606682(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_606683, base: "/",
    url: url_DeleteApiKey_606684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_606727 = ref object of OpenApiRestCall_605573
proc url_TestInvokeAuthorizer_606729(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeAuthorizer_606728(path: JsonNode; query: JsonNode;
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
  var valid_606730 = path.getOrDefault("restapi_id")
  valid_606730 = validateParameter(valid_606730, JString, required = true,
                                 default = nil)
  if valid_606730 != nil:
    section.add "restapi_id", valid_606730
  var valid_606731 = path.getOrDefault("authorizer_id")
  valid_606731 = validateParameter(valid_606731, JString, required = true,
                                 default = nil)
  if valid_606731 != nil:
    section.add "authorizer_id", valid_606731
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606732 = header.getOrDefault("X-Amz-Signature")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Signature", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Content-Sha256", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Date")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Date", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Credential")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Credential", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Security-Token")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Security-Token", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Algorithm")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Algorithm", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-SignedHeaders", valid_606738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606740: Call_TestInvokeAuthorizer_606727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_606740.validator(path, query, header, formData, body)
  let scheme = call_606740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606740.url(scheme.get, call_606740.host, call_606740.base,
                         call_606740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606740, url, valid)

proc call*(call_606741: Call_TestInvokeAuthorizer_606727; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  var path_606742 = newJObject()
  var body_606743 = newJObject()
  add(path_606742, "restapi_id", newJString(restapiId))
  add(path_606742, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_606743 = body
  result = call_606741.call(path_606742, nil, nil, nil, body_606743)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_606727(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_606728, base: "/",
    url: url_TestInvokeAuthorizer_606729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_606712 = ref object of OpenApiRestCall_605573
proc url_GetAuthorizer_606714(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_606713(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606715 = path.getOrDefault("restapi_id")
  valid_606715 = validateParameter(valid_606715, JString, required = true,
                                 default = nil)
  if valid_606715 != nil:
    section.add "restapi_id", valid_606715
  var valid_606716 = path.getOrDefault("authorizer_id")
  valid_606716 = validateParameter(valid_606716, JString, required = true,
                                 default = nil)
  if valid_606716 != nil:
    section.add "authorizer_id", valid_606716
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606717 = header.getOrDefault("X-Amz-Signature")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Signature", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Content-Sha256", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Date")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Date", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Credential")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Credential", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Security-Token")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Security-Token", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Algorithm")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Algorithm", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-SignedHeaders", valid_606723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606724: Call_GetAuthorizer_606712; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_606724.validator(path, query, header, formData, body)
  let scheme = call_606724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606724.url(scheme.get, call_606724.host, call_606724.base,
                         call_606724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606724, url, valid)

proc call*(call_606725: Call_GetAuthorizer_606712; restapiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_606726 = newJObject()
  add(path_606726, "restapi_id", newJString(restapiId))
  add(path_606726, "authorizer_id", newJString(authorizerId))
  result = call_606725.call(path_606726, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_606712(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_606713, base: "/", url: url_GetAuthorizer_606714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_606759 = ref object of OpenApiRestCall_605573
proc url_UpdateAuthorizer_606761(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_606760(path: JsonNode; query: JsonNode;
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
  var valid_606762 = path.getOrDefault("restapi_id")
  valid_606762 = validateParameter(valid_606762, JString, required = true,
                                 default = nil)
  if valid_606762 != nil:
    section.add "restapi_id", valid_606762
  var valid_606763 = path.getOrDefault("authorizer_id")
  valid_606763 = validateParameter(valid_606763, JString, required = true,
                                 default = nil)
  if valid_606763 != nil:
    section.add "authorizer_id", valid_606763
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606764 = header.getOrDefault("X-Amz-Signature")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Signature", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Content-Sha256", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Date")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Date", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Credential")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Credential", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Security-Token")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Security-Token", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Algorithm")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Algorithm", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-SignedHeaders", valid_606770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606772: Call_UpdateAuthorizer_606759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_606772.validator(path, query, header, formData, body)
  let scheme = call_606772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606772.url(scheme.get, call_606772.host, call_606772.base,
                         call_606772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606772, url, valid)

proc call*(call_606773: Call_UpdateAuthorizer_606759; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  var path_606774 = newJObject()
  var body_606775 = newJObject()
  add(path_606774, "restapi_id", newJString(restapiId))
  add(path_606774, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_606775 = body
  result = call_606773.call(path_606774, nil, nil, nil, body_606775)

var updateAuthorizer* = Call_UpdateAuthorizer_606759(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_606760, base: "/",
    url: url_UpdateAuthorizer_606761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_606744 = ref object of OpenApiRestCall_605573
proc url_DeleteAuthorizer_606746(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_606745(path: JsonNode; query: JsonNode;
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
  var valid_606747 = path.getOrDefault("restapi_id")
  valid_606747 = validateParameter(valid_606747, JString, required = true,
                                 default = nil)
  if valid_606747 != nil:
    section.add "restapi_id", valid_606747
  var valid_606748 = path.getOrDefault("authorizer_id")
  valid_606748 = validateParameter(valid_606748, JString, required = true,
                                 default = nil)
  if valid_606748 != nil:
    section.add "authorizer_id", valid_606748
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606749 = header.getOrDefault("X-Amz-Signature")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Signature", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Content-Sha256", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Date")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Date", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Credential")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Credential", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Security-Token")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Security-Token", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Algorithm")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Algorithm", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-SignedHeaders", valid_606755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606756: Call_DeleteAuthorizer_606744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_606756.validator(path, query, header, formData, body)
  let scheme = call_606756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606756.url(scheme.get, call_606756.host, call_606756.base,
                         call_606756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606756, url, valid)

proc call*(call_606757: Call_DeleteAuthorizer_606744; restapiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_606758 = newJObject()
  add(path_606758, "restapi_id", newJString(restapiId))
  add(path_606758, "authorizer_id", newJString(authorizerId))
  result = call_606757.call(path_606758, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_606744(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_606745, base: "/",
    url: url_DeleteAuthorizer_606746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_606776 = ref object of OpenApiRestCall_605573
proc url_GetBasePathMapping_606778(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMapping_606777(path: JsonNode; query: JsonNode;
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
  var valid_606779 = path.getOrDefault("base_path")
  valid_606779 = validateParameter(valid_606779, JString, required = true,
                                 default = nil)
  if valid_606779 != nil:
    section.add "base_path", valid_606779
  var valid_606780 = path.getOrDefault("domain_name")
  valid_606780 = validateParameter(valid_606780, JString, required = true,
                                 default = nil)
  if valid_606780 != nil:
    section.add "domain_name", valid_606780
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_606788: Call_GetBasePathMapping_606776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_606788.validator(path, query, header, formData, body)
  let scheme = call_606788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606788.url(scheme.get, call_606788.host, call_606788.base,
                         call_606788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606788, url, valid)

proc call*(call_606789: Call_GetBasePathMapping_606776; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_606790 = newJObject()
  add(path_606790, "base_path", newJString(basePath))
  add(path_606790, "domain_name", newJString(domainName))
  result = call_606789.call(path_606790, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_606776(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_606777, base: "/",
    url: url_GetBasePathMapping_606778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_606806 = ref object of OpenApiRestCall_605573
proc url_UpdateBasePathMapping_606808(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBasePathMapping_606807(path: JsonNode; query: JsonNode;
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
  var valid_606809 = path.getOrDefault("base_path")
  valid_606809 = validateParameter(valid_606809, JString, required = true,
                                 default = nil)
  if valid_606809 != nil:
    section.add "base_path", valid_606809
  var valid_606810 = path.getOrDefault("domain_name")
  valid_606810 = validateParameter(valid_606810, JString, required = true,
                                 default = nil)
  if valid_606810 != nil:
    section.add "domain_name", valid_606810
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606811 = header.getOrDefault("X-Amz-Signature")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Signature", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Content-Sha256", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Date")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Date", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Credential")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Credential", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Security-Token")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Security-Token", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Algorithm")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Algorithm", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-SignedHeaders", valid_606817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606819: Call_UpdateBasePathMapping_606806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_606819.validator(path, query, header, formData, body)
  let scheme = call_606819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606819.url(scheme.get, call_606819.host, call_606819.base,
                         call_606819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606819, url, valid)

proc call*(call_606820: Call_UpdateBasePathMapping_606806; basePath: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  var path_606821 = newJObject()
  var body_606822 = newJObject()
  add(path_606821, "base_path", newJString(basePath))
  if body != nil:
    body_606822 = body
  add(path_606821, "domain_name", newJString(domainName))
  result = call_606820.call(path_606821, nil, nil, nil, body_606822)

var updateBasePathMapping* = Call_UpdateBasePathMapping_606806(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_606807, base: "/",
    url: url_UpdateBasePathMapping_606808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_606791 = ref object of OpenApiRestCall_605573
proc url_DeleteBasePathMapping_606793(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBasePathMapping_606792(path: JsonNode; query: JsonNode;
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
  var valid_606794 = path.getOrDefault("base_path")
  valid_606794 = validateParameter(valid_606794, JString, required = true,
                                 default = nil)
  if valid_606794 != nil:
    section.add "base_path", valid_606794
  var valid_606795 = path.getOrDefault("domain_name")
  valid_606795 = validateParameter(valid_606795, JString, required = true,
                                 default = nil)
  if valid_606795 != nil:
    section.add "domain_name", valid_606795
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606796 = header.getOrDefault("X-Amz-Signature")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Signature", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Content-Sha256", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Date")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Date", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Credential")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Credential", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Security-Token")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Security-Token", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Algorithm")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Algorithm", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-SignedHeaders", valid_606802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606803: Call_DeleteBasePathMapping_606791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_606803.validator(path, query, header, formData, body)
  let scheme = call_606803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606803.url(scheme.get, call_606803.host, call_606803.base,
                         call_606803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606803, url, valid)

proc call*(call_606804: Call_DeleteBasePathMapping_606791; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_606805 = newJObject()
  add(path_606805, "base_path", newJString(basePath))
  add(path_606805, "domain_name", newJString(domainName))
  result = call_606804.call(path_606805, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_606791(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_606792, base: "/",
    url: url_DeleteBasePathMapping_606793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_606823 = ref object of OpenApiRestCall_605573
proc url_GetClientCertificate_606825(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificate_606824(path: JsonNode; query: JsonNode;
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
  var valid_606826 = path.getOrDefault("clientcertificate_id")
  valid_606826 = validateParameter(valid_606826, JString, required = true,
                                 default = nil)
  if valid_606826 != nil:
    section.add "clientcertificate_id", valid_606826
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606827 = header.getOrDefault("X-Amz-Signature")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Signature", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Content-Sha256", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Date")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Date", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Credential")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Credential", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Security-Token")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Security-Token", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Algorithm")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Algorithm", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-SignedHeaders", valid_606833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606834: Call_GetClientCertificate_606823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_606834.validator(path, query, header, formData, body)
  let scheme = call_606834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606834.url(scheme.get, call_606834.host, call_606834.base,
                         call_606834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606834, url, valid)

proc call*(call_606835: Call_GetClientCertificate_606823;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_606836 = newJObject()
  add(path_606836, "clientcertificate_id", newJString(clientcertificateId))
  result = call_606835.call(path_606836, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_606823(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_606824, base: "/",
    url: url_GetClientCertificate_606825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_606851 = ref object of OpenApiRestCall_605573
proc url_UpdateClientCertificate_606853(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClientCertificate_606852(path: JsonNode; query: JsonNode;
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
  var valid_606854 = path.getOrDefault("clientcertificate_id")
  valid_606854 = validateParameter(valid_606854, JString, required = true,
                                 default = nil)
  if valid_606854 != nil:
    section.add "clientcertificate_id", valid_606854
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606855 = header.getOrDefault("X-Amz-Signature")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Signature", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Content-Sha256", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Date")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Date", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Credential")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Credential", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Security-Token")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Security-Token", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Algorithm")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Algorithm", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-SignedHeaders", valid_606861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606863: Call_UpdateClientCertificate_606851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_606863.validator(path, query, header, formData, body)
  let scheme = call_606863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606863.url(scheme.get, call_606863.host, call_606863.base,
                         call_606863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606863, url, valid)

proc call*(call_606864: Call_UpdateClientCertificate_606851;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_606865 = newJObject()
  var body_606866 = newJObject()
  add(path_606865, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_606866 = body
  result = call_606864.call(path_606865, nil, nil, nil, body_606866)

var updateClientCertificate* = Call_UpdateClientCertificate_606851(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_606852, base: "/",
    url: url_UpdateClientCertificate_606853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_606837 = ref object of OpenApiRestCall_605573
proc url_DeleteClientCertificate_606839(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClientCertificate_606838(path: JsonNode; query: JsonNode;
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
  var valid_606840 = path.getOrDefault("clientcertificate_id")
  valid_606840 = validateParameter(valid_606840, JString, required = true,
                                 default = nil)
  if valid_606840 != nil:
    section.add "clientcertificate_id", valid_606840
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_606848: Call_DeleteClientCertificate_606837; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_606848.validator(path, query, header, formData, body)
  let scheme = call_606848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606848.url(scheme.get, call_606848.host, call_606848.base,
                         call_606848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606848, url, valid)

proc call*(call_606849: Call_DeleteClientCertificate_606837;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_606850 = newJObject()
  add(path_606850, "clientcertificate_id", newJString(clientcertificateId))
  result = call_606849.call(path_606850, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_606837(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_606838, base: "/",
    url: url_DeleteClientCertificate_606839, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_606867 = ref object of OpenApiRestCall_605573
proc url_GetDeployment_606869(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_606868(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606870 = path.getOrDefault("deployment_id")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = nil)
  if valid_606870 != nil:
    section.add "deployment_id", valid_606870
  var valid_606871 = path.getOrDefault("restapi_id")
  valid_606871 = validateParameter(valid_606871, JString, required = true,
                                 default = nil)
  if valid_606871 != nil:
    section.add "restapi_id", valid_606871
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_606872 = query.getOrDefault("embed")
  valid_606872 = validateParameter(valid_606872, JArray, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "embed", valid_606872
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606873 = header.getOrDefault("X-Amz-Signature")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Signature", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Content-Sha256", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Date")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Date", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Credential")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Credential", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Security-Token")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Security-Token", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Algorithm")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Algorithm", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-SignedHeaders", valid_606879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606880: Call_GetDeployment_606867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_606880.validator(path, query, header, formData, body)
  let scheme = call_606880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606880.url(scheme.get, call_606880.host, call_606880.base,
                         call_606880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606880, url, valid)

proc call*(call_606881: Call_GetDeployment_606867; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  var path_606882 = newJObject()
  var query_606883 = newJObject()
  add(path_606882, "deployment_id", newJString(deploymentId))
  add(path_606882, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_606883.add "embed", embed
  result = call_606881.call(path_606882, query_606883, nil, nil, nil)

var getDeployment* = Call_GetDeployment_606867(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_606868, base: "/", url: url_GetDeployment_606869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_606899 = ref object of OpenApiRestCall_605573
proc url_UpdateDeployment_606901(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_606900(path: JsonNode; query: JsonNode;
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
  var valid_606902 = path.getOrDefault("deployment_id")
  valid_606902 = validateParameter(valid_606902, JString, required = true,
                                 default = nil)
  if valid_606902 != nil:
    section.add "deployment_id", valid_606902
  var valid_606903 = path.getOrDefault("restapi_id")
  valid_606903 = validateParameter(valid_606903, JString, required = true,
                                 default = nil)
  if valid_606903 != nil:
    section.add "restapi_id", valid_606903
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606904 = header.getOrDefault("X-Amz-Signature")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Signature", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Content-Sha256", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Date")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Date", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Credential")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Credential", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Security-Token")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Security-Token", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Algorithm")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Algorithm", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-SignedHeaders", valid_606910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606912: Call_UpdateDeployment_606899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_606912.validator(path, query, header, formData, body)
  let scheme = call_606912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606912.url(scheme.get, call_606912.host, call_606912.base,
                         call_606912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606912, url, valid)

proc call*(call_606913: Call_UpdateDeployment_606899; deploymentId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606914 = newJObject()
  var body_606915 = newJObject()
  add(path_606914, "deployment_id", newJString(deploymentId))
  add(path_606914, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606915 = body
  result = call_606913.call(path_606914, nil, nil, nil, body_606915)

var updateDeployment* = Call_UpdateDeployment_606899(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_606900, base: "/",
    url: url_UpdateDeployment_606901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_606884 = ref object of OpenApiRestCall_605573
proc url_DeleteDeployment_606886(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_606885(path: JsonNode; query: JsonNode;
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
  var valid_606887 = path.getOrDefault("deployment_id")
  valid_606887 = validateParameter(valid_606887, JString, required = true,
                                 default = nil)
  if valid_606887 != nil:
    section.add "deployment_id", valid_606887
  var valid_606888 = path.getOrDefault("restapi_id")
  valid_606888 = validateParameter(valid_606888, JString, required = true,
                                 default = nil)
  if valid_606888 != nil:
    section.add "restapi_id", valid_606888
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606889 = header.getOrDefault("X-Amz-Signature")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Signature", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Content-Sha256", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Date")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Date", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Credential")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Credential", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Security-Token")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Security-Token", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Algorithm")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Algorithm", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-SignedHeaders", valid_606895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606896: Call_DeleteDeployment_606884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_606896.validator(path, query, header, formData, body)
  let scheme = call_606896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606896.url(scheme.get, call_606896.host, call_606896.base,
                         call_606896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606896, url, valid)

proc call*(call_606897: Call_DeleteDeployment_606884; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606898 = newJObject()
  add(path_606898, "deployment_id", newJString(deploymentId))
  add(path_606898, "restapi_id", newJString(restapiId))
  result = call_606897.call(path_606898, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_606884(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_606885, base: "/",
    url: url_DeleteDeployment_606886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_606916 = ref object of OpenApiRestCall_605573
proc url_GetDocumentationPart_606918(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationPart_606917(path: JsonNode; query: JsonNode;
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
  var valid_606919 = path.getOrDefault("part_id")
  valid_606919 = validateParameter(valid_606919, JString, required = true,
                                 default = nil)
  if valid_606919 != nil:
    section.add "part_id", valid_606919
  var valid_606920 = path.getOrDefault("restapi_id")
  valid_606920 = validateParameter(valid_606920, JString, required = true,
                                 default = nil)
  if valid_606920 != nil:
    section.add "restapi_id", valid_606920
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606921 = header.getOrDefault("X-Amz-Signature")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Signature", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Content-Sha256", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Date")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Date", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Credential")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Credential", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Security-Token")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Security-Token", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Algorithm")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Algorithm", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-SignedHeaders", valid_606927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606928: Call_GetDocumentationPart_606916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606928.validator(path, query, header, formData, body)
  let scheme = call_606928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606928.url(scheme.get, call_606928.host, call_606928.base,
                         call_606928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606928, url, valid)

proc call*(call_606929: Call_GetDocumentationPart_606916; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606930 = newJObject()
  add(path_606930, "part_id", newJString(partId))
  add(path_606930, "restapi_id", newJString(restapiId))
  result = call_606929.call(path_606930, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_606916(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_606917, base: "/",
    url: url_GetDocumentationPart_606918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_606946 = ref object of OpenApiRestCall_605573
proc url_UpdateDocumentationPart_606948(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentationPart_606947(path: JsonNode; query: JsonNode;
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
  var valid_606949 = path.getOrDefault("part_id")
  valid_606949 = validateParameter(valid_606949, JString, required = true,
                                 default = nil)
  if valid_606949 != nil:
    section.add "part_id", valid_606949
  var valid_606950 = path.getOrDefault("restapi_id")
  valid_606950 = validateParameter(valid_606950, JString, required = true,
                                 default = nil)
  if valid_606950 != nil:
    section.add "restapi_id", valid_606950
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606951 = header.getOrDefault("X-Amz-Signature")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Signature", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Content-Sha256", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-Date")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Date", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Credential")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Credential", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Security-Token")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Security-Token", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Algorithm")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Algorithm", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-SignedHeaders", valid_606957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606959: Call_UpdateDocumentationPart_606946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606959.validator(path, query, header, formData, body)
  let scheme = call_606959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606959.url(scheme.get, call_606959.host, call_606959.base,
                         call_606959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606959, url, valid)

proc call*(call_606960: Call_UpdateDocumentationPart_606946; partId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_606961 = newJObject()
  var body_606962 = newJObject()
  add(path_606961, "part_id", newJString(partId))
  add(path_606961, "restapi_id", newJString(restapiId))
  if body != nil:
    body_606962 = body
  result = call_606960.call(path_606961, nil, nil, nil, body_606962)

var updateDocumentationPart* = Call_UpdateDocumentationPart_606946(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_606947, base: "/",
    url: url_UpdateDocumentationPart_606948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_606931 = ref object of OpenApiRestCall_605573
proc url_DeleteDocumentationPart_606933(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocumentationPart_606932(path: JsonNode; query: JsonNode;
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
  var valid_606934 = path.getOrDefault("part_id")
  valid_606934 = validateParameter(valid_606934, JString, required = true,
                                 default = nil)
  if valid_606934 != nil:
    section.add "part_id", valid_606934
  var valid_606935 = path.getOrDefault("restapi_id")
  valid_606935 = validateParameter(valid_606935, JString, required = true,
                                 default = nil)
  if valid_606935 != nil:
    section.add "restapi_id", valid_606935
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606936 = header.getOrDefault("X-Amz-Signature")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Signature", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Content-Sha256", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Date")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Date", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Credential")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Credential", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Security-Token")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Security-Token", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Algorithm")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Algorithm", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-SignedHeaders", valid_606942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606943: Call_DeleteDocumentationPart_606931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606943.validator(path, query, header, formData, body)
  let scheme = call_606943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606943.url(scheme.get, call_606943.host, call_606943.base,
                         call_606943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606943, url, valid)

proc call*(call_606944: Call_DeleteDocumentationPart_606931; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606945 = newJObject()
  add(path_606945, "part_id", newJString(partId))
  add(path_606945, "restapi_id", newJString(restapiId))
  result = call_606944.call(path_606945, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_606931(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_606932, base: "/",
    url: url_DeleteDocumentationPart_606933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_606963 = ref object of OpenApiRestCall_605573
proc url_GetDocumentationVersion_606965(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationVersion_606964(path: JsonNode; query: JsonNode;
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
  var valid_606966 = path.getOrDefault("doc_version")
  valid_606966 = validateParameter(valid_606966, JString, required = true,
                                 default = nil)
  if valid_606966 != nil:
    section.add "doc_version", valid_606966
  var valid_606967 = path.getOrDefault("restapi_id")
  valid_606967 = validateParameter(valid_606967, JString, required = true,
                                 default = nil)
  if valid_606967 != nil:
    section.add "restapi_id", valid_606967
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606968 = header.getOrDefault("X-Amz-Signature")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "X-Amz-Signature", valid_606968
  var valid_606969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Content-Sha256", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Date")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Date", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-Credential")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-Credential", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Security-Token")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Security-Token", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Algorithm")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Algorithm", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-SignedHeaders", valid_606974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606975: Call_GetDocumentationVersion_606963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606975.validator(path, query, header, formData, body)
  let scheme = call_606975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606975.url(scheme.get, call_606975.host, call_606975.base,
                         call_606975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606975, url, valid)

proc call*(call_606976: Call_GetDocumentationVersion_606963; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606977 = newJObject()
  add(path_606977, "doc_version", newJString(docVersion))
  add(path_606977, "restapi_id", newJString(restapiId))
  result = call_606976.call(path_606977, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_606963(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_606964, base: "/",
    url: url_GetDocumentationVersion_606965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_606993 = ref object of OpenApiRestCall_605573
proc url_UpdateDocumentationVersion_606995(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentationVersion_606994(path: JsonNode; query: JsonNode;
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
  var valid_606996 = path.getOrDefault("doc_version")
  valid_606996 = validateParameter(valid_606996, JString, required = true,
                                 default = nil)
  if valid_606996 != nil:
    section.add "doc_version", valid_606996
  var valid_606997 = path.getOrDefault("restapi_id")
  valid_606997 = validateParameter(valid_606997, JString, required = true,
                                 default = nil)
  if valid_606997 != nil:
    section.add "restapi_id", valid_606997
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606998 = header.getOrDefault("X-Amz-Signature")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Signature", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Content-Sha256", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Date")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Date", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-Credential")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-Credential", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-Security-Token")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-Security-Token", valid_607002
  var valid_607003 = header.getOrDefault("X-Amz-Algorithm")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-Algorithm", valid_607003
  var valid_607004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "X-Amz-SignedHeaders", valid_607004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607006: Call_UpdateDocumentationVersion_606993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607006.validator(path, query, header, formData, body)
  let scheme = call_607006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607006.url(scheme.get, call_607006.host, call_607006.base,
                         call_607006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607006, url, valid)

proc call*(call_607007: Call_UpdateDocumentationVersion_606993; docVersion: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  ##   body: JObject (required)
  var path_607008 = newJObject()
  var body_607009 = newJObject()
  add(path_607008, "doc_version", newJString(docVersion))
  add(path_607008, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607009 = body
  result = call_607007.call(path_607008, nil, nil, nil, body_607009)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_606993(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_606994, base: "/",
    url: url_UpdateDocumentationVersion_606995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_606978 = ref object of OpenApiRestCall_605573
proc url_DeleteDocumentationVersion_606980(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentationVersion_606979(path: JsonNode; query: JsonNode;
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
  var valid_606981 = path.getOrDefault("doc_version")
  valid_606981 = validateParameter(valid_606981, JString, required = true,
                                 default = nil)
  if valid_606981 != nil:
    section.add "doc_version", valid_606981
  var valid_606982 = path.getOrDefault("restapi_id")
  valid_606982 = validateParameter(valid_606982, JString, required = true,
                                 default = nil)
  if valid_606982 != nil:
    section.add "restapi_id", valid_606982
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606983 = header.getOrDefault("X-Amz-Signature")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Signature", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Content-Sha256", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Date")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Date", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-Credential")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Credential", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Security-Token")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Security-Token", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Algorithm")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Algorithm", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-SignedHeaders", valid_606989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606990: Call_DeleteDocumentationVersion_606978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606990.validator(path, query, header, formData, body)
  let scheme = call_606990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606990.url(scheme.get, call_606990.host, call_606990.base,
                         call_606990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606990, url, valid)

proc call*(call_606991: Call_DeleteDocumentationVersion_606978; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_606992 = newJObject()
  add(path_606992, "doc_version", newJString(docVersion))
  add(path_606992, "restapi_id", newJString(restapiId))
  result = call_606991.call(path_606992, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_606978(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_606979, base: "/",
    url: url_DeleteDocumentationVersion_606980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_607010 = ref object of OpenApiRestCall_605573
proc url_GetDomainName_607012(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_607011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607013 = path.getOrDefault("domain_name")
  valid_607013 = validateParameter(valid_607013, JString, required = true,
                                 default = nil)
  if valid_607013 != nil:
    section.add "domain_name", valid_607013
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607014 = header.getOrDefault("X-Amz-Signature")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "X-Amz-Signature", valid_607014
  var valid_607015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "X-Amz-Content-Sha256", valid_607015
  var valid_607016 = header.getOrDefault("X-Amz-Date")
  valid_607016 = validateParameter(valid_607016, JString, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "X-Amz-Date", valid_607016
  var valid_607017 = header.getOrDefault("X-Amz-Credential")
  valid_607017 = validateParameter(valid_607017, JString, required = false,
                                 default = nil)
  if valid_607017 != nil:
    section.add "X-Amz-Credential", valid_607017
  var valid_607018 = header.getOrDefault("X-Amz-Security-Token")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "X-Amz-Security-Token", valid_607018
  var valid_607019 = header.getOrDefault("X-Amz-Algorithm")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Algorithm", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-SignedHeaders", valid_607020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607021: Call_GetDomainName_607010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_607021.validator(path, query, header, formData, body)
  let scheme = call_607021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607021.url(scheme.get, call_607021.host, call_607021.base,
                         call_607021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607021, url, valid)

proc call*(call_607022: Call_GetDomainName_607010; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_607023 = newJObject()
  add(path_607023, "domain_name", newJString(domainName))
  result = call_607022.call(path_607023, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_607010(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_607011,
    base: "/", url: url_GetDomainName_607012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_607038 = ref object of OpenApiRestCall_605573
proc url_UpdateDomainName_607040(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_607039(path: JsonNode; query: JsonNode;
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
  var valid_607041 = path.getOrDefault("domain_name")
  valid_607041 = validateParameter(valid_607041, JString, required = true,
                                 default = nil)
  if valid_607041 != nil:
    section.add "domain_name", valid_607041
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607042 = header.getOrDefault("X-Amz-Signature")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "X-Amz-Signature", valid_607042
  var valid_607043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Content-Sha256", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Date")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Date", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Credential")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Credential", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Security-Token")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Security-Token", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Algorithm")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Algorithm", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-SignedHeaders", valid_607048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607050: Call_UpdateDomainName_607038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_607050.validator(path, query, header, formData, body)
  let scheme = call_607050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607050.url(scheme.get, call_607050.host, call_607050.base,
                         call_607050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607050, url, valid)

proc call*(call_607051: Call_UpdateDomainName_607038; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  var path_607052 = newJObject()
  var body_607053 = newJObject()
  if body != nil:
    body_607053 = body
  add(path_607052, "domain_name", newJString(domainName))
  result = call_607051.call(path_607052, nil, nil, nil, body_607053)

var updateDomainName* = Call_UpdateDomainName_607038(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_607039,
    base: "/", url: url_UpdateDomainName_607040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_607024 = ref object of OpenApiRestCall_605573
proc url_DeleteDomainName_607026(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_607025(path: JsonNode; query: JsonNode;
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
  var valid_607027 = path.getOrDefault("domain_name")
  valid_607027 = validateParameter(valid_607027, JString, required = true,
                                 default = nil)
  if valid_607027 != nil:
    section.add "domain_name", valid_607027
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607028 = header.getOrDefault("X-Amz-Signature")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-Signature", valid_607028
  var valid_607029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Content-Sha256", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-Date")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-Date", valid_607030
  var valid_607031 = header.getOrDefault("X-Amz-Credential")
  valid_607031 = validateParameter(valid_607031, JString, required = false,
                                 default = nil)
  if valid_607031 != nil:
    section.add "X-Amz-Credential", valid_607031
  var valid_607032 = header.getOrDefault("X-Amz-Security-Token")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Security-Token", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Algorithm")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Algorithm", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-SignedHeaders", valid_607034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607035: Call_DeleteDomainName_607024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_607035.validator(path, query, header, formData, body)
  let scheme = call_607035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607035.url(scheme.get, call_607035.host, call_607035.base,
                         call_607035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607035, url, valid)

proc call*(call_607036: Call_DeleteDomainName_607024; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_607037 = newJObject()
  add(path_607037, "domain_name", newJString(domainName))
  result = call_607036.call(path_607037, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_607024(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_607025,
    base: "/", url: url_DeleteDomainName_607026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_607069 = ref object of OpenApiRestCall_605573
proc url_PutGatewayResponse_607071(protocol: Scheme; host: string; base: string;
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

proc validate_PutGatewayResponse_607070(path: JsonNode; query: JsonNode;
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
  assert path != nil,
        "path argument is necessary due to required `response_type` field"
  var valid_607072 = path.getOrDefault("response_type")
  valid_607072 = validateParameter(valid_607072, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_607072 != nil:
    section.add "response_type", valid_607072
  var valid_607073 = path.getOrDefault("restapi_id")
  valid_607073 = validateParameter(valid_607073, JString, required = true,
                                 default = nil)
  if valid_607073 != nil:
    section.add "restapi_id", valid_607073
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607074 = header.getOrDefault("X-Amz-Signature")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Signature", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Content-Sha256", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Date")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Date", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Credential")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Credential", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Security-Token")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Security-Token", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Algorithm")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Algorithm", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-SignedHeaders", valid_607080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607082: Call_PutGatewayResponse_607069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_607082.validator(path, query, header, formData, body)
  let scheme = call_607082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607082.url(scheme.get, call_607082.host, call_607082.base,
                         call_607082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607082, url, valid)

proc call*(call_607083: Call_PutGatewayResponse_607069; restapiId: string;
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
  var path_607084 = newJObject()
  var body_607085 = newJObject()
  add(path_607084, "response_type", newJString(responseType))
  add(path_607084, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607085 = body
  result = call_607083.call(path_607084, nil, nil, nil, body_607085)

var putGatewayResponse* = Call_PutGatewayResponse_607069(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_607070, base: "/",
    url: url_PutGatewayResponse_607071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_607054 = ref object of OpenApiRestCall_605573
proc url_GetGatewayResponse_607056(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponse_607055(path: JsonNode; query: JsonNode;
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
  assert path != nil,
        "path argument is necessary due to required `response_type` field"
  var valid_607057 = path.getOrDefault("response_type")
  valid_607057 = validateParameter(valid_607057, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_607057 != nil:
    section.add "response_type", valid_607057
  var valid_607058 = path.getOrDefault("restapi_id")
  valid_607058 = validateParameter(valid_607058, JString, required = true,
                                 default = nil)
  if valid_607058 != nil:
    section.add "restapi_id", valid_607058
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607059 = header.getOrDefault("X-Amz-Signature")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Signature", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Content-Sha256", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Date")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Date", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Credential")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Credential", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-Security-Token")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Security-Token", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Algorithm")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Algorithm", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-SignedHeaders", valid_607065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607066: Call_GetGatewayResponse_607054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_607066.validator(path, query, header, formData, body)
  let scheme = call_607066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607066.url(scheme.get, call_607066.host, call_607066.base,
                         call_607066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607066, url, valid)

proc call*(call_607067: Call_GetGatewayResponse_607054; restapiId: string;
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
  var path_607068 = newJObject()
  add(path_607068, "response_type", newJString(responseType))
  add(path_607068, "restapi_id", newJString(restapiId))
  result = call_607067.call(path_607068, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_607054(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_607055, base: "/",
    url: url_GetGatewayResponse_607056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_607101 = ref object of OpenApiRestCall_605573
proc url_UpdateGatewayResponse_607103(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayResponse_607102(path: JsonNode; query: JsonNode;
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
  assert path != nil,
        "path argument is necessary due to required `response_type` field"
  var valid_607104 = path.getOrDefault("response_type")
  valid_607104 = validateParameter(valid_607104, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_607104 != nil:
    section.add "response_type", valid_607104
  var valid_607105 = path.getOrDefault("restapi_id")
  valid_607105 = validateParameter(valid_607105, JString, required = true,
                                 default = nil)
  if valid_607105 != nil:
    section.add "restapi_id", valid_607105
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607106 = header.getOrDefault("X-Amz-Signature")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "X-Amz-Signature", valid_607106
  var valid_607107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-Content-Sha256", valid_607107
  var valid_607108 = header.getOrDefault("X-Amz-Date")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Date", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Credential")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Credential", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Security-Token")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Security-Token", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Algorithm")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Algorithm", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-SignedHeaders", valid_607112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607114: Call_UpdateGatewayResponse_607101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_607114.validator(path, query, header, formData, body)
  let scheme = call_607114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607114.url(scheme.get, call_607114.host, call_607114.base,
                         call_607114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607114, url, valid)

proc call*(call_607115: Call_UpdateGatewayResponse_607101; restapiId: string;
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
  var path_607116 = newJObject()
  var body_607117 = newJObject()
  add(path_607116, "response_type", newJString(responseType))
  add(path_607116, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607117 = body
  result = call_607115.call(path_607116, nil, nil, nil, body_607117)

var updateGatewayResponse* = Call_UpdateGatewayResponse_607101(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_607102, base: "/",
    url: url_UpdateGatewayResponse_607103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_607086 = ref object of OpenApiRestCall_605573
proc url_DeleteGatewayResponse_607088(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayResponse_607087(path: JsonNode; query: JsonNode;
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
  assert path != nil,
        "path argument is necessary due to required `response_type` field"
  var valid_607089 = path.getOrDefault("response_type")
  valid_607089 = validateParameter(valid_607089, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_607089 != nil:
    section.add "response_type", valid_607089
  var valid_607090 = path.getOrDefault("restapi_id")
  valid_607090 = validateParameter(valid_607090, JString, required = true,
                                 default = nil)
  if valid_607090 != nil:
    section.add "restapi_id", valid_607090
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607091 = header.getOrDefault("X-Amz-Signature")
  valid_607091 = validateParameter(valid_607091, JString, required = false,
                                 default = nil)
  if valid_607091 != nil:
    section.add "X-Amz-Signature", valid_607091
  var valid_607092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "X-Amz-Content-Sha256", valid_607092
  var valid_607093 = header.getOrDefault("X-Amz-Date")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Date", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Credential")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Credential", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Security-Token")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Security-Token", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Algorithm")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Algorithm", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-SignedHeaders", valid_607097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607098: Call_DeleteGatewayResponse_607086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_607098.validator(path, query, header, formData, body)
  let scheme = call_607098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607098.url(scheme.get, call_607098.host, call_607098.base,
                         call_607098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607098, url, valid)

proc call*(call_607099: Call_DeleteGatewayResponse_607086; restapiId: string;
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
  var path_607100 = newJObject()
  add(path_607100, "response_type", newJString(responseType))
  add(path_607100, "restapi_id", newJString(restapiId))
  result = call_607099.call(path_607100, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_607086(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_607087, base: "/",
    url: url_DeleteGatewayResponse_607088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_607134 = ref object of OpenApiRestCall_605573
proc url_PutIntegration_607136(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegration_607135(path: JsonNode; query: JsonNode;
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
  var valid_607137 = path.getOrDefault("restapi_id")
  valid_607137 = validateParameter(valid_607137, JString, required = true,
                                 default = nil)
  if valid_607137 != nil:
    section.add "restapi_id", valid_607137
  var valid_607138 = path.getOrDefault("resource_id")
  valid_607138 = validateParameter(valid_607138, JString, required = true,
                                 default = nil)
  if valid_607138 != nil:
    section.add "resource_id", valid_607138
  var valid_607139 = path.getOrDefault("http_method")
  valid_607139 = validateParameter(valid_607139, JString, required = true,
                                 default = nil)
  if valid_607139 != nil:
    section.add "http_method", valid_607139
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607140 = header.getOrDefault("X-Amz-Signature")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-Signature", valid_607140
  var valid_607141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Content-Sha256", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Date")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Date", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-Credential")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Credential", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-Security-Token")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Security-Token", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Algorithm")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Algorithm", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-SignedHeaders", valid_607146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607148: Call_PutIntegration_607134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_607148.validator(path, query, header, formData, body)
  let scheme = call_607148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607148.url(scheme.get, call_607148.host, call_607148.base,
                         call_607148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607148, url, valid)

proc call*(call_607149: Call_PutIntegration_607134; restapiId: string;
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
  var path_607150 = newJObject()
  var body_607151 = newJObject()
  add(path_607150, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607151 = body
  add(path_607150, "resource_id", newJString(resourceId))
  add(path_607150, "http_method", newJString(httpMethod))
  result = call_607149.call(path_607150, nil, nil, nil, body_607151)

var putIntegration* = Call_PutIntegration_607134(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_607135, base: "/", url: url_PutIntegration_607136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_607118 = ref object of OpenApiRestCall_605573
proc url_GetIntegration_607120(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_607119(path: JsonNode; query: JsonNode;
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
  var valid_607121 = path.getOrDefault("restapi_id")
  valid_607121 = validateParameter(valid_607121, JString, required = true,
                                 default = nil)
  if valid_607121 != nil:
    section.add "restapi_id", valid_607121
  var valid_607122 = path.getOrDefault("resource_id")
  valid_607122 = validateParameter(valid_607122, JString, required = true,
                                 default = nil)
  if valid_607122 != nil:
    section.add "resource_id", valid_607122
  var valid_607123 = path.getOrDefault("http_method")
  valid_607123 = validateParameter(valid_607123, JString, required = true,
                                 default = nil)
  if valid_607123 != nil:
    section.add "http_method", valid_607123
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607124 = header.getOrDefault("X-Amz-Signature")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "X-Amz-Signature", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Content-Sha256", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Date")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Date", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-Credential")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-Credential", valid_607127
  var valid_607128 = header.getOrDefault("X-Amz-Security-Token")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Security-Token", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Algorithm")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Algorithm", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-SignedHeaders", valid_607130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607131: Call_GetIntegration_607118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_607131.validator(path, query, header, formData, body)
  let scheme = call_607131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607131.url(scheme.get, call_607131.host, call_607131.base,
                         call_607131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607131, url, valid)

proc call*(call_607132: Call_GetIntegration_607118; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  var path_607133 = newJObject()
  add(path_607133, "restapi_id", newJString(restapiId))
  add(path_607133, "resource_id", newJString(resourceId))
  add(path_607133, "http_method", newJString(httpMethod))
  result = call_607132.call(path_607133, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_607118(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_607119, base: "/", url: url_GetIntegration_607120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_607168 = ref object of OpenApiRestCall_605573
proc url_UpdateIntegration_607170(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_607169(path: JsonNode; query: JsonNode;
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
  var valid_607171 = path.getOrDefault("restapi_id")
  valid_607171 = validateParameter(valid_607171, JString, required = true,
                                 default = nil)
  if valid_607171 != nil:
    section.add "restapi_id", valid_607171
  var valid_607172 = path.getOrDefault("resource_id")
  valid_607172 = validateParameter(valid_607172, JString, required = true,
                                 default = nil)
  if valid_607172 != nil:
    section.add "resource_id", valid_607172
  var valid_607173 = path.getOrDefault("http_method")
  valid_607173 = validateParameter(valid_607173, JString, required = true,
                                 default = nil)
  if valid_607173 != nil:
    section.add "http_method", valid_607173
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607174 = header.getOrDefault("X-Amz-Signature")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-Signature", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Content-Sha256", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Date")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Date", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Credential")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Credential", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-Security-Token")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-Security-Token", valid_607178
  var valid_607179 = header.getOrDefault("X-Amz-Algorithm")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "X-Amz-Algorithm", valid_607179
  var valid_607180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "X-Amz-SignedHeaders", valid_607180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607182: Call_UpdateIntegration_607168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_607182.validator(path, query, header, formData, body)
  let scheme = call_607182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607182.url(scheme.get, call_607182.host, call_607182.base,
                         call_607182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607182, url, valid)

proc call*(call_607183: Call_UpdateIntegration_607168; restapiId: string;
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
  var path_607184 = newJObject()
  var body_607185 = newJObject()
  add(path_607184, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607185 = body
  add(path_607184, "resource_id", newJString(resourceId))
  add(path_607184, "http_method", newJString(httpMethod))
  result = call_607183.call(path_607184, nil, nil, nil, body_607185)

var updateIntegration* = Call_UpdateIntegration_607168(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_607169, base: "/",
    url: url_UpdateIntegration_607170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_607152 = ref object of OpenApiRestCall_605573
proc url_DeleteIntegration_607154(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_607153(path: JsonNode; query: JsonNode;
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
  var valid_607155 = path.getOrDefault("restapi_id")
  valid_607155 = validateParameter(valid_607155, JString, required = true,
                                 default = nil)
  if valid_607155 != nil:
    section.add "restapi_id", valid_607155
  var valid_607156 = path.getOrDefault("resource_id")
  valid_607156 = validateParameter(valid_607156, JString, required = true,
                                 default = nil)
  if valid_607156 != nil:
    section.add "resource_id", valid_607156
  var valid_607157 = path.getOrDefault("http_method")
  valid_607157 = validateParameter(valid_607157, JString, required = true,
                                 default = nil)
  if valid_607157 != nil:
    section.add "http_method", valid_607157
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_607165: Call_DeleteIntegration_607152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_607165.validator(path, query, header, formData, body)
  let scheme = call_607165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607165.url(scheme.get, call_607165.host, call_607165.base,
                         call_607165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607165, url, valid)

proc call*(call_607166: Call_DeleteIntegration_607152; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  var path_607167 = newJObject()
  add(path_607167, "restapi_id", newJString(restapiId))
  add(path_607167, "resource_id", newJString(resourceId))
  add(path_607167, "http_method", newJString(httpMethod))
  result = call_607166.call(path_607167, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_607152(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_607153, base: "/",
    url: url_DeleteIntegration_607154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_607203 = ref object of OpenApiRestCall_605573
proc url_PutIntegrationResponse_607205(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegrationResponse_607204(path: JsonNode; query: JsonNode;
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
  var valid_607206 = path.getOrDefault("status_code")
  valid_607206 = validateParameter(valid_607206, JString, required = true,
                                 default = nil)
  if valid_607206 != nil:
    section.add "status_code", valid_607206
  var valid_607207 = path.getOrDefault("restapi_id")
  valid_607207 = validateParameter(valid_607207, JString, required = true,
                                 default = nil)
  if valid_607207 != nil:
    section.add "restapi_id", valid_607207
  var valid_607208 = path.getOrDefault("resource_id")
  valid_607208 = validateParameter(valid_607208, JString, required = true,
                                 default = nil)
  if valid_607208 != nil:
    section.add "resource_id", valid_607208
  var valid_607209 = path.getOrDefault("http_method")
  valid_607209 = validateParameter(valid_607209, JString, required = true,
                                 default = nil)
  if valid_607209 != nil:
    section.add "http_method", valid_607209
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607210 = header.getOrDefault("X-Amz-Signature")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "X-Amz-Signature", valid_607210
  var valid_607211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "X-Amz-Content-Sha256", valid_607211
  var valid_607212 = header.getOrDefault("X-Amz-Date")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "X-Amz-Date", valid_607212
  var valid_607213 = header.getOrDefault("X-Amz-Credential")
  valid_607213 = validateParameter(valid_607213, JString, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "X-Amz-Credential", valid_607213
  var valid_607214 = header.getOrDefault("X-Amz-Security-Token")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "X-Amz-Security-Token", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Algorithm")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Algorithm", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-SignedHeaders", valid_607216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607218: Call_PutIntegrationResponse_607203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_607218.validator(path, query, header, formData, body)
  let scheme = call_607218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607218.url(scheme.get, call_607218.host, call_607218.base,
                         call_607218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607218, url, valid)

proc call*(call_607219: Call_PutIntegrationResponse_607203; statusCode: string;
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
  var path_607220 = newJObject()
  var body_607221 = newJObject()
  add(path_607220, "status_code", newJString(statusCode))
  add(path_607220, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607221 = body
  add(path_607220, "resource_id", newJString(resourceId))
  add(path_607220, "http_method", newJString(httpMethod))
  result = call_607219.call(path_607220, nil, nil, nil, body_607221)

var putIntegrationResponse* = Call_PutIntegrationResponse_607203(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_607204, base: "/",
    url: url_PutIntegrationResponse_607205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_607186 = ref object of OpenApiRestCall_605573
proc url_GetIntegrationResponse_607188(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_607187(path: JsonNode; query: JsonNode;
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
  var valid_607189 = path.getOrDefault("status_code")
  valid_607189 = validateParameter(valid_607189, JString, required = true,
                                 default = nil)
  if valid_607189 != nil:
    section.add "status_code", valid_607189
  var valid_607190 = path.getOrDefault("restapi_id")
  valid_607190 = validateParameter(valid_607190, JString, required = true,
                                 default = nil)
  if valid_607190 != nil:
    section.add "restapi_id", valid_607190
  var valid_607191 = path.getOrDefault("resource_id")
  valid_607191 = validateParameter(valid_607191, JString, required = true,
                                 default = nil)
  if valid_607191 != nil:
    section.add "resource_id", valid_607191
  var valid_607192 = path.getOrDefault("http_method")
  valid_607192 = validateParameter(valid_607192, JString, required = true,
                                 default = nil)
  if valid_607192 != nil:
    section.add "http_method", valid_607192
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607193 = header.getOrDefault("X-Amz-Signature")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-Signature", valid_607193
  var valid_607194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607194 = validateParameter(valid_607194, JString, required = false,
                                 default = nil)
  if valid_607194 != nil:
    section.add "X-Amz-Content-Sha256", valid_607194
  var valid_607195 = header.getOrDefault("X-Amz-Date")
  valid_607195 = validateParameter(valid_607195, JString, required = false,
                                 default = nil)
  if valid_607195 != nil:
    section.add "X-Amz-Date", valid_607195
  var valid_607196 = header.getOrDefault("X-Amz-Credential")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "X-Amz-Credential", valid_607196
  var valid_607197 = header.getOrDefault("X-Amz-Security-Token")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Security-Token", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Algorithm")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Algorithm", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-SignedHeaders", valid_607199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607200: Call_GetIntegrationResponse_607186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_607200.validator(path, query, header, formData, body)
  let scheme = call_607200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607200.url(scheme.get, call_607200.host, call_607200.base,
                         call_607200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607200, url, valid)

proc call*(call_607201: Call_GetIntegrationResponse_607186; statusCode: string;
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
  var path_607202 = newJObject()
  add(path_607202, "status_code", newJString(statusCode))
  add(path_607202, "restapi_id", newJString(restapiId))
  add(path_607202, "resource_id", newJString(resourceId))
  add(path_607202, "http_method", newJString(httpMethod))
  result = call_607201.call(path_607202, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_607186(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_607187, base: "/",
    url: url_GetIntegrationResponse_607188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_607239 = ref object of OpenApiRestCall_605573
proc url_UpdateIntegrationResponse_607241(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_607240(path: JsonNode; query: JsonNode;
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
  var valid_607242 = path.getOrDefault("status_code")
  valid_607242 = validateParameter(valid_607242, JString, required = true,
                                 default = nil)
  if valid_607242 != nil:
    section.add "status_code", valid_607242
  var valid_607243 = path.getOrDefault("restapi_id")
  valid_607243 = validateParameter(valid_607243, JString, required = true,
                                 default = nil)
  if valid_607243 != nil:
    section.add "restapi_id", valid_607243
  var valid_607244 = path.getOrDefault("resource_id")
  valid_607244 = validateParameter(valid_607244, JString, required = true,
                                 default = nil)
  if valid_607244 != nil:
    section.add "resource_id", valid_607244
  var valid_607245 = path.getOrDefault("http_method")
  valid_607245 = validateParameter(valid_607245, JString, required = true,
                                 default = nil)
  if valid_607245 != nil:
    section.add "http_method", valid_607245
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607246 = header.getOrDefault("X-Amz-Signature")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Signature", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Content-Sha256", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Date")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Date", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Credential")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Credential", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Security-Token")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Security-Token", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Algorithm")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Algorithm", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-SignedHeaders", valid_607252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607254: Call_UpdateIntegrationResponse_607239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_607254.validator(path, query, header, formData, body)
  let scheme = call_607254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607254.url(scheme.get, call_607254.host, call_607254.base,
                         call_607254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607254, url, valid)

proc call*(call_607255: Call_UpdateIntegrationResponse_607239; statusCode: string;
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
  var path_607256 = newJObject()
  var body_607257 = newJObject()
  add(path_607256, "status_code", newJString(statusCode))
  add(path_607256, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607257 = body
  add(path_607256, "resource_id", newJString(resourceId))
  add(path_607256, "http_method", newJString(httpMethod))
  result = call_607255.call(path_607256, nil, nil, nil, body_607257)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_607239(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_607240, base: "/",
    url: url_UpdateIntegrationResponse_607241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_607222 = ref object of OpenApiRestCall_605573
proc url_DeleteIntegrationResponse_607224(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_607223(path: JsonNode; query: JsonNode;
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
  var valid_607225 = path.getOrDefault("status_code")
  valid_607225 = validateParameter(valid_607225, JString, required = true,
                                 default = nil)
  if valid_607225 != nil:
    section.add "status_code", valid_607225
  var valid_607226 = path.getOrDefault("restapi_id")
  valid_607226 = validateParameter(valid_607226, JString, required = true,
                                 default = nil)
  if valid_607226 != nil:
    section.add "restapi_id", valid_607226
  var valid_607227 = path.getOrDefault("resource_id")
  valid_607227 = validateParameter(valid_607227, JString, required = true,
                                 default = nil)
  if valid_607227 != nil:
    section.add "resource_id", valid_607227
  var valid_607228 = path.getOrDefault("http_method")
  valid_607228 = validateParameter(valid_607228, JString, required = true,
                                 default = nil)
  if valid_607228 != nil:
    section.add "http_method", valid_607228
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607229 = header.getOrDefault("X-Amz-Signature")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-Signature", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Content-Sha256", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Date")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Date", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Credential")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Credential", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Security-Token")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Security-Token", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Algorithm")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Algorithm", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-SignedHeaders", valid_607235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607236: Call_DeleteIntegrationResponse_607222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_607236.validator(path, query, header, formData, body)
  let scheme = call_607236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607236.url(scheme.get, call_607236.host, call_607236.base,
                         call_607236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607236, url, valid)

proc call*(call_607237: Call_DeleteIntegrationResponse_607222; statusCode: string;
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
  var path_607238 = newJObject()
  add(path_607238, "status_code", newJString(statusCode))
  add(path_607238, "restapi_id", newJString(restapiId))
  add(path_607238, "resource_id", newJString(resourceId))
  add(path_607238, "http_method", newJString(httpMethod))
  result = call_607237.call(path_607238, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_607222(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_607223, base: "/",
    url: url_DeleteIntegrationResponse_607224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_607274 = ref object of OpenApiRestCall_605573
proc url_PutMethod_607276(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutMethod_607275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607277 = path.getOrDefault("restapi_id")
  valid_607277 = validateParameter(valid_607277, JString, required = true,
                                 default = nil)
  if valid_607277 != nil:
    section.add "restapi_id", valid_607277
  var valid_607278 = path.getOrDefault("resource_id")
  valid_607278 = validateParameter(valid_607278, JString, required = true,
                                 default = nil)
  if valid_607278 != nil:
    section.add "resource_id", valid_607278
  var valid_607279 = path.getOrDefault("http_method")
  valid_607279 = validateParameter(valid_607279, JString, required = true,
                                 default = nil)
  if valid_607279 != nil:
    section.add "http_method", valid_607279
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607280 = header.getOrDefault("X-Amz-Signature")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Signature", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Content-Sha256", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Date")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Date", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-Credential")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Credential", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Security-Token")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Security-Token", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-Algorithm")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-Algorithm", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-SignedHeaders", valid_607286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607288: Call_PutMethod_607274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_607288.validator(path, query, header, formData, body)
  let scheme = call_607288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607288.url(scheme.get, call_607288.host, call_607288.base,
                         call_607288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607288, url, valid)

proc call*(call_607289: Call_PutMethod_607274; restapiId: string; body: JsonNode;
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
  var path_607290 = newJObject()
  var body_607291 = newJObject()
  add(path_607290, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607291 = body
  add(path_607290, "resource_id", newJString(resourceId))
  add(path_607290, "http_method", newJString(httpMethod))
  result = call_607289.call(path_607290, nil, nil, nil, body_607291)

var putMethod* = Call_PutMethod_607274(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_607275,
                                    base: "/", url: url_PutMethod_607276,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_607292 = ref object of OpenApiRestCall_605573
proc url_TestInvokeMethod_607294(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeMethod_607293(path: JsonNode; query: JsonNode;
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
  var valid_607295 = path.getOrDefault("restapi_id")
  valid_607295 = validateParameter(valid_607295, JString, required = true,
                                 default = nil)
  if valid_607295 != nil:
    section.add "restapi_id", valid_607295
  var valid_607296 = path.getOrDefault("resource_id")
  valid_607296 = validateParameter(valid_607296, JString, required = true,
                                 default = nil)
  if valid_607296 != nil:
    section.add "resource_id", valid_607296
  var valid_607297 = path.getOrDefault("http_method")
  valid_607297 = validateParameter(valid_607297, JString, required = true,
                                 default = nil)
  if valid_607297 != nil:
    section.add "http_method", valid_607297
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607298 = header.getOrDefault("X-Amz-Signature")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Signature", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Content-Sha256", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-Date")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Date", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-Credential")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Credential", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Security-Token")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Security-Token", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Algorithm")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Algorithm", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-SignedHeaders", valid_607304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607306: Call_TestInvokeMethod_607292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_607306.validator(path, query, header, formData, body)
  let scheme = call_607306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607306.url(scheme.get, call_607306.host, call_607306.base,
                         call_607306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607306, url, valid)

proc call*(call_607307: Call_TestInvokeMethod_607292; restapiId: string;
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
  var path_607308 = newJObject()
  var body_607309 = newJObject()
  add(path_607308, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607309 = body
  add(path_607308, "resource_id", newJString(resourceId))
  add(path_607308, "http_method", newJString(httpMethod))
  result = call_607307.call(path_607308, nil, nil, nil, body_607309)

var testInvokeMethod* = Call_TestInvokeMethod_607292(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_607293, base: "/",
    url: url_TestInvokeMethod_607294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_607258 = ref object of OpenApiRestCall_605573
proc url_GetMethod_607260(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMethod_607259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607261 = path.getOrDefault("restapi_id")
  valid_607261 = validateParameter(valid_607261, JString, required = true,
                                 default = nil)
  if valid_607261 != nil:
    section.add "restapi_id", valid_607261
  var valid_607262 = path.getOrDefault("resource_id")
  valid_607262 = validateParameter(valid_607262, JString, required = true,
                                 default = nil)
  if valid_607262 != nil:
    section.add "resource_id", valid_607262
  var valid_607263 = path.getOrDefault("http_method")
  valid_607263 = validateParameter(valid_607263, JString, required = true,
                                 default = nil)
  if valid_607263 != nil:
    section.add "http_method", valid_607263
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607264 = header.getOrDefault("X-Amz-Signature")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Signature", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Content-Sha256", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Date")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Date", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Credential")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Credential", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Security-Token")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Security-Token", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Algorithm")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Algorithm", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-SignedHeaders", valid_607270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607271: Call_GetMethod_607258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_607271.validator(path, query, header, formData, body)
  let scheme = call_607271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607271.url(scheme.get, call_607271.host, call_607271.base,
                         call_607271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607271, url, valid)

proc call*(call_607272: Call_GetMethod_607258; restapiId: string; resourceId: string;
          httpMethod: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  var path_607273 = newJObject()
  add(path_607273, "restapi_id", newJString(restapiId))
  add(path_607273, "resource_id", newJString(resourceId))
  add(path_607273, "http_method", newJString(httpMethod))
  result = call_607272.call(path_607273, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_607258(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_607259,
                                    base: "/", url: url_GetMethod_607260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_607326 = ref object of OpenApiRestCall_605573
proc url_UpdateMethod_607328(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethod_607327(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607329 = path.getOrDefault("restapi_id")
  valid_607329 = validateParameter(valid_607329, JString, required = true,
                                 default = nil)
  if valid_607329 != nil:
    section.add "restapi_id", valid_607329
  var valid_607330 = path.getOrDefault("resource_id")
  valid_607330 = validateParameter(valid_607330, JString, required = true,
                                 default = nil)
  if valid_607330 != nil:
    section.add "resource_id", valid_607330
  var valid_607331 = path.getOrDefault("http_method")
  valid_607331 = validateParameter(valid_607331, JString, required = true,
                                 default = nil)
  if valid_607331 != nil:
    section.add "http_method", valid_607331
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607332 = header.getOrDefault("X-Amz-Signature")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "X-Amz-Signature", valid_607332
  var valid_607333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "X-Amz-Content-Sha256", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Date")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Date", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Credential")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Credential", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Security-Token")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Security-Token", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Algorithm")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Algorithm", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-SignedHeaders", valid_607338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607340: Call_UpdateMethod_607326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_607340.validator(path, query, header, formData, body)
  let scheme = call_607340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607340.url(scheme.get, call_607340.host, call_607340.base,
                         call_607340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607340, url, valid)

proc call*(call_607341: Call_UpdateMethod_607326; restapiId: string; body: JsonNode;
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
  var path_607342 = newJObject()
  var body_607343 = newJObject()
  add(path_607342, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607343 = body
  add(path_607342, "resource_id", newJString(resourceId))
  add(path_607342, "http_method", newJString(httpMethod))
  result = call_607341.call(path_607342, nil, nil, nil, body_607343)

var updateMethod* = Call_UpdateMethod_607326(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_607327, base: "/", url: url_UpdateMethod_607328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_607310 = ref object of OpenApiRestCall_605573
proc url_DeleteMethod_607312(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethod_607311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607313 = path.getOrDefault("restapi_id")
  valid_607313 = validateParameter(valid_607313, JString, required = true,
                                 default = nil)
  if valid_607313 != nil:
    section.add "restapi_id", valid_607313
  var valid_607314 = path.getOrDefault("resource_id")
  valid_607314 = validateParameter(valid_607314, JString, required = true,
                                 default = nil)
  if valid_607314 != nil:
    section.add "resource_id", valid_607314
  var valid_607315 = path.getOrDefault("http_method")
  valid_607315 = validateParameter(valid_607315, JString, required = true,
                                 default = nil)
  if valid_607315 != nil:
    section.add "http_method", valid_607315
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607316 = header.getOrDefault("X-Amz-Signature")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-Signature", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Content-Sha256", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-Date")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-Date", valid_607318
  var valid_607319 = header.getOrDefault("X-Amz-Credential")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Credential", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Security-Token")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Security-Token", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Algorithm")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Algorithm", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-SignedHeaders", valid_607322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607323: Call_DeleteMethod_607310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_607323.validator(path, query, header, formData, body)
  let scheme = call_607323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607323.url(scheme.get, call_607323.host, call_607323.base,
                         call_607323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607323, url, valid)

proc call*(call_607324: Call_DeleteMethod_607310; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_607325 = newJObject()
  add(path_607325, "restapi_id", newJString(restapiId))
  add(path_607325, "resource_id", newJString(resourceId))
  add(path_607325, "http_method", newJString(httpMethod))
  result = call_607324.call(path_607325, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_607310(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_607311, base: "/", url: url_DeleteMethod_607312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_607361 = ref object of OpenApiRestCall_605573
proc url_PutMethodResponse_607363(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethodResponse_607362(path: JsonNode; query: JsonNode;
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
  var valid_607364 = path.getOrDefault("status_code")
  valid_607364 = validateParameter(valid_607364, JString, required = true,
                                 default = nil)
  if valid_607364 != nil:
    section.add "status_code", valid_607364
  var valid_607365 = path.getOrDefault("restapi_id")
  valid_607365 = validateParameter(valid_607365, JString, required = true,
                                 default = nil)
  if valid_607365 != nil:
    section.add "restapi_id", valid_607365
  var valid_607366 = path.getOrDefault("resource_id")
  valid_607366 = validateParameter(valid_607366, JString, required = true,
                                 default = nil)
  if valid_607366 != nil:
    section.add "resource_id", valid_607366
  var valid_607367 = path.getOrDefault("http_method")
  valid_607367 = validateParameter(valid_607367, JString, required = true,
                                 default = nil)
  if valid_607367 != nil:
    section.add "http_method", valid_607367
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607368 = header.getOrDefault("X-Amz-Signature")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Signature", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Content-Sha256", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Date")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Date", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Credential")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Credential", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Security-Token")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Security-Token", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-Algorithm")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-Algorithm", valid_607373
  var valid_607374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-SignedHeaders", valid_607374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607376: Call_PutMethodResponse_607361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_607376.validator(path, query, header, formData, body)
  let scheme = call_607376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607376.url(scheme.get, call_607376.host, call_607376.base,
                         call_607376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607376, url, valid)

proc call*(call_607377: Call_PutMethodResponse_607361; statusCode: string;
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
  var path_607378 = newJObject()
  var body_607379 = newJObject()
  add(path_607378, "status_code", newJString(statusCode))
  add(path_607378, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607379 = body
  add(path_607378, "resource_id", newJString(resourceId))
  add(path_607378, "http_method", newJString(httpMethod))
  result = call_607377.call(path_607378, nil, nil, nil, body_607379)

var putMethodResponse* = Call_PutMethodResponse_607361(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_607362, base: "/",
    url: url_PutMethodResponse_607363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_607344 = ref object of OpenApiRestCall_605573
proc url_GetMethodResponse_607346(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethodResponse_607345(path: JsonNode; query: JsonNode;
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
  var valid_607347 = path.getOrDefault("status_code")
  valid_607347 = validateParameter(valid_607347, JString, required = true,
                                 default = nil)
  if valid_607347 != nil:
    section.add "status_code", valid_607347
  var valid_607348 = path.getOrDefault("restapi_id")
  valid_607348 = validateParameter(valid_607348, JString, required = true,
                                 default = nil)
  if valid_607348 != nil:
    section.add "restapi_id", valid_607348
  var valid_607349 = path.getOrDefault("resource_id")
  valid_607349 = validateParameter(valid_607349, JString, required = true,
                                 default = nil)
  if valid_607349 != nil:
    section.add "resource_id", valid_607349
  var valid_607350 = path.getOrDefault("http_method")
  valid_607350 = validateParameter(valid_607350, JString, required = true,
                                 default = nil)
  if valid_607350 != nil:
    section.add "http_method", valid_607350
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607351 = header.getOrDefault("X-Amz-Signature")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Signature", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Content-Sha256", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Date")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Date", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Credential")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Credential", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Security-Token")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Security-Token", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Algorithm")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Algorithm", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-SignedHeaders", valid_607357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607358: Call_GetMethodResponse_607344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_607358.validator(path, query, header, formData, body)
  let scheme = call_607358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607358.url(scheme.get, call_607358.host, call_607358.base,
                         call_607358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607358, url, valid)

proc call*(call_607359: Call_GetMethodResponse_607344; statusCode: string;
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
  var path_607360 = newJObject()
  add(path_607360, "status_code", newJString(statusCode))
  add(path_607360, "restapi_id", newJString(restapiId))
  add(path_607360, "resource_id", newJString(resourceId))
  add(path_607360, "http_method", newJString(httpMethod))
  result = call_607359.call(path_607360, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_607344(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_607345, base: "/",
    url: url_GetMethodResponse_607346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_607397 = ref object of OpenApiRestCall_605573
proc url_UpdateMethodResponse_607399(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethodResponse_607398(path: JsonNode; query: JsonNode;
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
  var valid_607400 = path.getOrDefault("status_code")
  valid_607400 = validateParameter(valid_607400, JString, required = true,
                                 default = nil)
  if valid_607400 != nil:
    section.add "status_code", valid_607400
  var valid_607401 = path.getOrDefault("restapi_id")
  valid_607401 = validateParameter(valid_607401, JString, required = true,
                                 default = nil)
  if valid_607401 != nil:
    section.add "restapi_id", valid_607401
  var valid_607402 = path.getOrDefault("resource_id")
  valid_607402 = validateParameter(valid_607402, JString, required = true,
                                 default = nil)
  if valid_607402 != nil:
    section.add "resource_id", valid_607402
  var valid_607403 = path.getOrDefault("http_method")
  valid_607403 = validateParameter(valid_607403, JString, required = true,
                                 default = nil)
  if valid_607403 != nil:
    section.add "http_method", valid_607403
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607404 = header.getOrDefault("X-Amz-Signature")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Signature", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Content-Sha256", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-Date")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-Date", valid_607406
  var valid_607407 = header.getOrDefault("X-Amz-Credential")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "X-Amz-Credential", valid_607407
  var valid_607408 = header.getOrDefault("X-Amz-Security-Token")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "X-Amz-Security-Token", valid_607408
  var valid_607409 = header.getOrDefault("X-Amz-Algorithm")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "X-Amz-Algorithm", valid_607409
  var valid_607410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "X-Amz-SignedHeaders", valid_607410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607412: Call_UpdateMethodResponse_607397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_607412.validator(path, query, header, formData, body)
  let scheme = call_607412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607412.url(scheme.get, call_607412.host, call_607412.base,
                         call_607412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607412, url, valid)

proc call*(call_607413: Call_UpdateMethodResponse_607397; statusCode: string;
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
  var path_607414 = newJObject()
  var body_607415 = newJObject()
  add(path_607414, "status_code", newJString(statusCode))
  add(path_607414, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607415 = body
  add(path_607414, "resource_id", newJString(resourceId))
  add(path_607414, "http_method", newJString(httpMethod))
  result = call_607413.call(path_607414, nil, nil, nil, body_607415)

var updateMethodResponse* = Call_UpdateMethodResponse_607397(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_607398, base: "/",
    url: url_UpdateMethodResponse_607399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_607380 = ref object of OpenApiRestCall_605573
proc url_DeleteMethodResponse_607382(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethodResponse_607381(path: JsonNode; query: JsonNode;
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
  var valid_607383 = path.getOrDefault("status_code")
  valid_607383 = validateParameter(valid_607383, JString, required = true,
                                 default = nil)
  if valid_607383 != nil:
    section.add "status_code", valid_607383
  var valid_607384 = path.getOrDefault("restapi_id")
  valid_607384 = validateParameter(valid_607384, JString, required = true,
                                 default = nil)
  if valid_607384 != nil:
    section.add "restapi_id", valid_607384
  var valid_607385 = path.getOrDefault("resource_id")
  valid_607385 = validateParameter(valid_607385, JString, required = true,
                                 default = nil)
  if valid_607385 != nil:
    section.add "resource_id", valid_607385
  var valid_607386 = path.getOrDefault("http_method")
  valid_607386 = validateParameter(valid_607386, JString, required = true,
                                 default = nil)
  if valid_607386 != nil:
    section.add "http_method", valid_607386
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607387 = header.getOrDefault("X-Amz-Signature")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Signature", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Content-Sha256", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-Date")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-Date", valid_607389
  var valid_607390 = header.getOrDefault("X-Amz-Credential")
  valid_607390 = validateParameter(valid_607390, JString, required = false,
                                 default = nil)
  if valid_607390 != nil:
    section.add "X-Amz-Credential", valid_607390
  var valid_607391 = header.getOrDefault("X-Amz-Security-Token")
  valid_607391 = validateParameter(valid_607391, JString, required = false,
                                 default = nil)
  if valid_607391 != nil:
    section.add "X-Amz-Security-Token", valid_607391
  var valid_607392 = header.getOrDefault("X-Amz-Algorithm")
  valid_607392 = validateParameter(valid_607392, JString, required = false,
                                 default = nil)
  if valid_607392 != nil:
    section.add "X-Amz-Algorithm", valid_607392
  var valid_607393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607393 = validateParameter(valid_607393, JString, required = false,
                                 default = nil)
  if valid_607393 != nil:
    section.add "X-Amz-SignedHeaders", valid_607393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607394: Call_DeleteMethodResponse_607380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_607394.validator(path, query, header, formData, body)
  let scheme = call_607394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607394.url(scheme.get, call_607394.host, call_607394.base,
                         call_607394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607394, url, valid)

proc call*(call_607395: Call_DeleteMethodResponse_607380; statusCode: string;
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
  var path_607396 = newJObject()
  add(path_607396, "status_code", newJString(statusCode))
  add(path_607396, "restapi_id", newJString(restapiId))
  add(path_607396, "resource_id", newJString(resourceId))
  add(path_607396, "http_method", newJString(httpMethod))
  result = call_607395.call(path_607396, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_607380(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_607381, base: "/",
    url: url_DeleteMethodResponse_607382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_607416 = ref object of OpenApiRestCall_605573
proc url_GetModel_607418(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_607417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607419 = path.getOrDefault("model_name")
  valid_607419 = validateParameter(valid_607419, JString, required = true,
                                 default = nil)
  if valid_607419 != nil:
    section.add "model_name", valid_607419
  var valid_607420 = path.getOrDefault("restapi_id")
  valid_607420 = validateParameter(valid_607420, JString, required = true,
                                 default = nil)
  if valid_607420 != nil:
    section.add "restapi_id", valid_607420
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_607421 = query.getOrDefault("flatten")
  valid_607421 = validateParameter(valid_607421, JBool, required = false, default = nil)
  if valid_607421 != nil:
    section.add "flatten", valid_607421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607422 = header.getOrDefault("X-Amz-Signature")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-Signature", valid_607422
  var valid_607423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607423 = validateParameter(valid_607423, JString, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "X-Amz-Content-Sha256", valid_607423
  var valid_607424 = header.getOrDefault("X-Amz-Date")
  valid_607424 = validateParameter(valid_607424, JString, required = false,
                                 default = nil)
  if valid_607424 != nil:
    section.add "X-Amz-Date", valid_607424
  var valid_607425 = header.getOrDefault("X-Amz-Credential")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Credential", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-Security-Token")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-Security-Token", valid_607426
  var valid_607427 = header.getOrDefault("X-Amz-Algorithm")
  valid_607427 = validateParameter(valid_607427, JString, required = false,
                                 default = nil)
  if valid_607427 != nil:
    section.add "X-Amz-Algorithm", valid_607427
  var valid_607428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "X-Amz-SignedHeaders", valid_607428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607429: Call_GetModel_607416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_607429.validator(path, query, header, formData, body)
  let scheme = call_607429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607429.url(scheme.get, call_607429.host, call_607429.base,
                         call_607429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607429, url, valid)

proc call*(call_607430: Call_GetModel_607416; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_607431 = newJObject()
  var query_607432 = newJObject()
  add(query_607432, "flatten", newJBool(flatten))
  add(path_607431, "model_name", newJString(modelName))
  add(path_607431, "restapi_id", newJString(restapiId))
  result = call_607430.call(path_607431, query_607432, nil, nil, nil)

var getModel* = Call_GetModel_607416(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_607417, base: "/",
                                  url: url_GetModel_607418,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_607448 = ref object of OpenApiRestCall_605573
proc url_UpdateModel_607450(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_607449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607451 = path.getOrDefault("model_name")
  valid_607451 = validateParameter(valid_607451, JString, required = true,
                                 default = nil)
  if valid_607451 != nil:
    section.add "model_name", valid_607451
  var valid_607452 = path.getOrDefault("restapi_id")
  valid_607452 = validateParameter(valid_607452, JString, required = true,
                                 default = nil)
  if valid_607452 != nil:
    section.add "restapi_id", valid_607452
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607453 = header.getOrDefault("X-Amz-Signature")
  valid_607453 = validateParameter(valid_607453, JString, required = false,
                                 default = nil)
  if valid_607453 != nil:
    section.add "X-Amz-Signature", valid_607453
  var valid_607454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "X-Amz-Content-Sha256", valid_607454
  var valid_607455 = header.getOrDefault("X-Amz-Date")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "X-Amz-Date", valid_607455
  var valid_607456 = header.getOrDefault("X-Amz-Credential")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "X-Amz-Credential", valid_607456
  var valid_607457 = header.getOrDefault("X-Amz-Security-Token")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "X-Amz-Security-Token", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-Algorithm")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-Algorithm", valid_607458
  var valid_607459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "X-Amz-SignedHeaders", valid_607459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607461: Call_UpdateModel_607448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_607461.validator(path, query, header, formData, body)
  let scheme = call_607461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607461.url(scheme.get, call_607461.host, call_607461.base,
                         call_607461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607461, url, valid)

proc call*(call_607462: Call_UpdateModel_607448; modelName: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_607463 = newJObject()
  var body_607464 = newJObject()
  add(path_607463, "model_name", newJString(modelName))
  add(path_607463, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607464 = body
  result = call_607462.call(path_607463, nil, nil, nil, body_607464)

var updateModel* = Call_UpdateModel_607448(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_607449,
                                        base: "/", url: url_UpdateModel_607450,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_607433 = ref object of OpenApiRestCall_605573
proc url_DeleteModel_607435(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_607434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607436 = path.getOrDefault("model_name")
  valid_607436 = validateParameter(valid_607436, JString, required = true,
                                 default = nil)
  if valid_607436 != nil:
    section.add "model_name", valid_607436
  var valid_607437 = path.getOrDefault("restapi_id")
  valid_607437 = validateParameter(valid_607437, JString, required = true,
                                 default = nil)
  if valid_607437 != nil:
    section.add "restapi_id", valid_607437
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607438 = header.getOrDefault("X-Amz-Signature")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Signature", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-Content-Sha256", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Date")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Date", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Credential")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Credential", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Security-Token")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Security-Token", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Algorithm")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Algorithm", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-SignedHeaders", valid_607444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607445: Call_DeleteModel_607433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_607445.validator(path, query, header, formData, body)
  let scheme = call_607445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607445.url(scheme.get, call_607445.host, call_607445.base,
                         call_607445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607445, url, valid)

proc call*(call_607446: Call_DeleteModel_607433; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_607447 = newJObject()
  add(path_607447, "model_name", newJString(modelName))
  add(path_607447, "restapi_id", newJString(restapiId))
  result = call_607446.call(path_607447, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_607433(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_607434,
                                        base: "/", url: url_DeleteModel_607435,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_607465 = ref object of OpenApiRestCall_605573
proc url_GetRequestValidator_607467(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidator_607466(path: JsonNode; query: JsonNode;
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
  var valid_607468 = path.getOrDefault("restapi_id")
  valid_607468 = validateParameter(valid_607468, JString, required = true,
                                 default = nil)
  if valid_607468 != nil:
    section.add "restapi_id", valid_607468
  var valid_607469 = path.getOrDefault("requestvalidator_id")
  valid_607469 = validateParameter(valid_607469, JString, required = true,
                                 default = nil)
  if valid_607469 != nil:
    section.add "requestvalidator_id", valid_607469
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607470 = header.getOrDefault("X-Amz-Signature")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Signature", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Content-Sha256", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-Date")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-Date", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-Credential")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-Credential", valid_607473
  var valid_607474 = header.getOrDefault("X-Amz-Security-Token")
  valid_607474 = validateParameter(valid_607474, JString, required = false,
                                 default = nil)
  if valid_607474 != nil:
    section.add "X-Amz-Security-Token", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Algorithm")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Algorithm", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-SignedHeaders", valid_607476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607477: Call_GetRequestValidator_607465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_607477.validator(path, query, header, formData, body)
  let scheme = call_607477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607477.url(scheme.get, call_607477.host, call_607477.base,
                         call_607477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607477, url, valid)

proc call*(call_607478: Call_GetRequestValidator_607465; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  var path_607479 = newJObject()
  add(path_607479, "restapi_id", newJString(restapiId))
  add(path_607479, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_607478.call(path_607479, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_607465(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_607466, base: "/",
    url: url_GetRequestValidator_607467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_607495 = ref object of OpenApiRestCall_605573
proc url_UpdateRequestValidator_607497(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRequestValidator_607496(path: JsonNode; query: JsonNode;
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
  var valid_607498 = path.getOrDefault("restapi_id")
  valid_607498 = validateParameter(valid_607498, JString, required = true,
                                 default = nil)
  if valid_607498 != nil:
    section.add "restapi_id", valid_607498
  var valid_607499 = path.getOrDefault("requestvalidator_id")
  valid_607499 = validateParameter(valid_607499, JString, required = true,
                                 default = nil)
  if valid_607499 != nil:
    section.add "requestvalidator_id", valid_607499
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607500 = header.getOrDefault("X-Amz-Signature")
  valid_607500 = validateParameter(valid_607500, JString, required = false,
                                 default = nil)
  if valid_607500 != nil:
    section.add "X-Amz-Signature", valid_607500
  var valid_607501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "X-Amz-Content-Sha256", valid_607501
  var valid_607502 = header.getOrDefault("X-Amz-Date")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "X-Amz-Date", valid_607502
  var valid_607503 = header.getOrDefault("X-Amz-Credential")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "X-Amz-Credential", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Security-Token")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Security-Token", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-Algorithm")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-Algorithm", valid_607505
  var valid_607506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-SignedHeaders", valid_607506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607508: Call_UpdateRequestValidator_607495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_607508.validator(path, query, header, formData, body)
  let scheme = call_607508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607508.url(scheme.get, call_607508.host, call_607508.base,
                         call_607508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607508, url, valid)

proc call*(call_607509: Call_UpdateRequestValidator_607495; restapiId: string;
          requestvalidatorId: string; body: JsonNode): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  var path_607510 = newJObject()
  var body_607511 = newJObject()
  add(path_607510, "restapi_id", newJString(restapiId))
  add(path_607510, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_607511 = body
  result = call_607509.call(path_607510, nil, nil, nil, body_607511)

var updateRequestValidator* = Call_UpdateRequestValidator_607495(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_607496, base: "/",
    url: url_UpdateRequestValidator_607497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_607480 = ref object of OpenApiRestCall_605573
proc url_DeleteRequestValidator_607482(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRequestValidator_607481(path: JsonNode; query: JsonNode;
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
  var valid_607483 = path.getOrDefault("restapi_id")
  valid_607483 = validateParameter(valid_607483, JString, required = true,
                                 default = nil)
  if valid_607483 != nil:
    section.add "restapi_id", valid_607483
  var valid_607484 = path.getOrDefault("requestvalidator_id")
  valid_607484 = validateParameter(valid_607484, JString, required = true,
                                 default = nil)
  if valid_607484 != nil:
    section.add "requestvalidator_id", valid_607484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607485 = header.getOrDefault("X-Amz-Signature")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-Signature", valid_607485
  var valid_607486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Content-Sha256", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-Date")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-Date", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-Credential")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-Credential", valid_607488
  var valid_607489 = header.getOrDefault("X-Amz-Security-Token")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-Security-Token", valid_607489
  var valid_607490 = header.getOrDefault("X-Amz-Algorithm")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Algorithm", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-SignedHeaders", valid_607491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607492: Call_DeleteRequestValidator_607480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_607492.validator(path, query, header, formData, body)
  let scheme = call_607492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607492.url(scheme.get, call_607492.host, call_607492.base,
                         call_607492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607492, url, valid)

proc call*(call_607493: Call_DeleteRequestValidator_607480; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  var path_607494 = newJObject()
  add(path_607494, "restapi_id", newJString(restapiId))
  add(path_607494, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_607493.call(path_607494, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_607480(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_607481, base: "/",
    url: url_DeleteRequestValidator_607482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_607512 = ref object of OpenApiRestCall_605573
proc url_GetResource_607514(protocol: Scheme; host: string; base: string;
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

proc validate_GetResource_607513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607515 = path.getOrDefault("restapi_id")
  valid_607515 = validateParameter(valid_607515, JString, required = true,
                                 default = nil)
  if valid_607515 != nil:
    section.add "restapi_id", valid_607515
  var valid_607516 = path.getOrDefault("resource_id")
  valid_607516 = validateParameter(valid_607516, JString, required = true,
                                 default = nil)
  if valid_607516 != nil:
    section.add "resource_id", valid_607516
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_607517 = query.getOrDefault("embed")
  valid_607517 = validateParameter(valid_607517, JArray, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "embed", valid_607517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607518 = header.getOrDefault("X-Amz-Signature")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Signature", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Content-Sha256", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Date")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Date", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-Credential")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-Credential", valid_607521
  var valid_607522 = header.getOrDefault("X-Amz-Security-Token")
  valid_607522 = validateParameter(valid_607522, JString, required = false,
                                 default = nil)
  if valid_607522 != nil:
    section.add "X-Amz-Security-Token", valid_607522
  var valid_607523 = header.getOrDefault("X-Amz-Algorithm")
  valid_607523 = validateParameter(valid_607523, JString, required = false,
                                 default = nil)
  if valid_607523 != nil:
    section.add "X-Amz-Algorithm", valid_607523
  var valid_607524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607524 = validateParameter(valid_607524, JString, required = false,
                                 default = nil)
  if valid_607524 != nil:
    section.add "X-Amz-SignedHeaders", valid_607524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607525: Call_GetResource_607512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_607525.validator(path, query, header, formData, body)
  let scheme = call_607525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607525.url(scheme.get, call_607525.host, call_607525.base,
                         call_607525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607525, url, valid)

proc call*(call_607526: Call_GetResource_607512; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_607527 = newJObject()
  var query_607528 = newJObject()
  add(path_607527, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_607528.add "embed", embed
  add(path_607527, "resource_id", newJString(resourceId))
  result = call_607526.call(path_607527, query_607528, nil, nil, nil)

var getResource* = Call_GetResource_607512(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_607513,
                                        base: "/", url: url_GetResource_607514,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_607544 = ref object of OpenApiRestCall_605573
proc url_UpdateResource_607546(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResource_607545(path: JsonNode; query: JsonNode;
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
  var valid_607547 = path.getOrDefault("restapi_id")
  valid_607547 = validateParameter(valid_607547, JString, required = true,
                                 default = nil)
  if valid_607547 != nil:
    section.add "restapi_id", valid_607547
  var valid_607548 = path.getOrDefault("resource_id")
  valid_607548 = validateParameter(valid_607548, JString, required = true,
                                 default = nil)
  if valid_607548 != nil:
    section.add "resource_id", valid_607548
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607549 = header.getOrDefault("X-Amz-Signature")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Signature", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Content-Sha256", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Date")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Date", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Credential")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Credential", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-Security-Token")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Security-Token", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-Algorithm")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-Algorithm", valid_607554
  var valid_607555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "X-Amz-SignedHeaders", valid_607555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607557: Call_UpdateResource_607544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_607557.validator(path, query, header, formData, body)
  let scheme = call_607557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607557.url(scheme.get, call_607557.host, call_607557.base,
                         call_607557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607557, url, valid)

proc call*(call_607558: Call_UpdateResource_607544; restapiId: string;
          body: JsonNode; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_607559 = newJObject()
  var body_607560 = newJObject()
  add(path_607559, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607560 = body
  add(path_607559, "resource_id", newJString(resourceId))
  result = call_607558.call(path_607559, nil, nil, nil, body_607560)

var updateResource* = Call_UpdateResource_607544(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_607545, base: "/", url: url_UpdateResource_607546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_607529 = ref object of OpenApiRestCall_605573
proc url_DeleteResource_607531(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResource_607530(path: JsonNode; query: JsonNode;
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
  var valid_607532 = path.getOrDefault("restapi_id")
  valid_607532 = validateParameter(valid_607532, JString, required = true,
                                 default = nil)
  if valid_607532 != nil:
    section.add "restapi_id", valid_607532
  var valid_607533 = path.getOrDefault("resource_id")
  valid_607533 = validateParameter(valid_607533, JString, required = true,
                                 default = nil)
  if valid_607533 != nil:
    section.add "resource_id", valid_607533
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607534 = header.getOrDefault("X-Amz-Signature")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Signature", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Content-Sha256", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-Date")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-Date", valid_607536
  var valid_607537 = header.getOrDefault("X-Amz-Credential")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "X-Amz-Credential", valid_607537
  var valid_607538 = header.getOrDefault("X-Amz-Security-Token")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-Security-Token", valid_607538
  var valid_607539 = header.getOrDefault("X-Amz-Algorithm")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "X-Amz-Algorithm", valid_607539
  var valid_607540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "X-Amz-SignedHeaders", valid_607540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607541: Call_DeleteResource_607529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_607541.validator(path, query, header, formData, body)
  let scheme = call_607541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607541.url(scheme.get, call_607541.host, call_607541.base,
                         call_607541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607541, url, valid)

proc call*(call_607542: Call_DeleteResource_607529; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_607543 = newJObject()
  add(path_607543, "restapi_id", newJString(restapiId))
  add(path_607543, "resource_id", newJString(resourceId))
  result = call_607542.call(path_607543, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_607529(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_607530, base: "/", url: url_DeleteResource_607531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_607575 = ref object of OpenApiRestCall_605573
proc url_PutRestApi_607577(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutRestApi_607576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607578 = path.getOrDefault("restapi_id")
  valid_607578 = validateParameter(valid_607578, JString, required = true,
                                 default = nil)
  if valid_607578 != nil:
    section.add "restapi_id", valid_607578
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
  var valid_607579 = query.getOrDefault("failonwarnings")
  valid_607579 = validateParameter(valid_607579, JBool, required = false, default = nil)
  if valid_607579 != nil:
    section.add "failonwarnings", valid_607579
  var valid_607580 = query.getOrDefault("parameters.2.value")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "parameters.2.value", valid_607580
  var valid_607581 = query.getOrDefault("parameters.1.value")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "parameters.1.value", valid_607581
  var valid_607582 = query.getOrDefault("mode")
  valid_607582 = validateParameter(valid_607582, JString, required = false,
                                 default = newJString("merge"))
  if valid_607582 != nil:
    section.add "mode", valid_607582
  var valid_607583 = query.getOrDefault("parameters.1.key")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "parameters.1.key", valid_607583
  var valid_607584 = query.getOrDefault("parameters.2.key")
  valid_607584 = validateParameter(valid_607584, JString, required = false,
                                 default = nil)
  if valid_607584 != nil:
    section.add "parameters.2.key", valid_607584
  var valid_607585 = query.getOrDefault("parameters.0.value")
  valid_607585 = validateParameter(valid_607585, JString, required = false,
                                 default = nil)
  if valid_607585 != nil:
    section.add "parameters.0.value", valid_607585
  var valid_607586 = query.getOrDefault("parameters.0.key")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "parameters.0.key", valid_607586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607587 = header.getOrDefault("X-Amz-Signature")
  valid_607587 = validateParameter(valid_607587, JString, required = false,
                                 default = nil)
  if valid_607587 != nil:
    section.add "X-Amz-Signature", valid_607587
  var valid_607588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607588 = validateParameter(valid_607588, JString, required = false,
                                 default = nil)
  if valid_607588 != nil:
    section.add "X-Amz-Content-Sha256", valid_607588
  var valid_607589 = header.getOrDefault("X-Amz-Date")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "X-Amz-Date", valid_607589
  var valid_607590 = header.getOrDefault("X-Amz-Credential")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "X-Amz-Credential", valid_607590
  var valid_607591 = header.getOrDefault("X-Amz-Security-Token")
  valid_607591 = validateParameter(valid_607591, JString, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "X-Amz-Security-Token", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Algorithm")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Algorithm", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-SignedHeaders", valid_607593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607595: Call_PutRestApi_607575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_607595.validator(path, query, header, formData, body)
  let scheme = call_607595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607595.url(scheme.get, call_607595.host, call_607595.base,
                         call_607595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607595, url, valid)

proc call*(call_607596: Call_PutRestApi_607575; restapiId: string; body: JsonNode;
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
  var path_607597 = newJObject()
  var query_607598 = newJObject()
  var body_607599 = newJObject()
  add(query_607598, "failonwarnings", newJBool(failonwarnings))
  add(query_607598, "parameters.2.value", newJString(parameters2Value))
  add(query_607598, "parameters.1.value", newJString(parameters1Value))
  add(query_607598, "mode", newJString(mode))
  add(query_607598, "parameters.1.key", newJString(parameters1Key))
  add(path_607597, "restapi_id", newJString(restapiId))
  add(query_607598, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_607599 = body
  add(query_607598, "parameters.0.value", newJString(parameters0Value))
  add(query_607598, "parameters.0.key", newJString(parameters0Key))
  result = call_607596.call(path_607597, query_607598, nil, nil, body_607599)

var putRestApi* = Call_PutRestApi_607575(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_607576,
                                      base: "/", url: url_PutRestApi_607577,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_607561 = ref object of OpenApiRestCall_605573
proc url_GetRestApi_607563(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRestApi_607562(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607564 = path.getOrDefault("restapi_id")
  valid_607564 = validateParameter(valid_607564, JString, required = true,
                                 default = nil)
  if valid_607564 != nil:
    section.add "restapi_id", valid_607564
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607565 = header.getOrDefault("X-Amz-Signature")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Signature", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Content-Sha256", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Date")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Date", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Credential")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Credential", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-Security-Token")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-Security-Token", valid_607569
  var valid_607570 = header.getOrDefault("X-Amz-Algorithm")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-Algorithm", valid_607570
  var valid_607571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "X-Amz-SignedHeaders", valid_607571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607572: Call_GetRestApi_607561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_607572.validator(path, query, header, formData, body)
  let scheme = call_607572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607572.url(scheme.get, call_607572.host, call_607572.base,
                         call_607572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607572, url, valid)

proc call*(call_607573: Call_GetRestApi_607561; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_607574 = newJObject()
  add(path_607574, "restapi_id", newJString(restapiId))
  result = call_607573.call(path_607574, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_607561(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_607562,
                                      base: "/", url: url_GetRestApi_607563,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_607614 = ref object of OpenApiRestCall_605573
proc url_UpdateRestApi_607616(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRestApi_607615(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607617 = path.getOrDefault("restapi_id")
  valid_607617 = validateParameter(valid_607617, JString, required = true,
                                 default = nil)
  if valid_607617 != nil:
    section.add "restapi_id", valid_607617
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607618 = header.getOrDefault("X-Amz-Signature")
  valid_607618 = validateParameter(valid_607618, JString, required = false,
                                 default = nil)
  if valid_607618 != nil:
    section.add "X-Amz-Signature", valid_607618
  var valid_607619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607619 = validateParameter(valid_607619, JString, required = false,
                                 default = nil)
  if valid_607619 != nil:
    section.add "X-Amz-Content-Sha256", valid_607619
  var valid_607620 = header.getOrDefault("X-Amz-Date")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "X-Amz-Date", valid_607620
  var valid_607621 = header.getOrDefault("X-Amz-Credential")
  valid_607621 = validateParameter(valid_607621, JString, required = false,
                                 default = nil)
  if valid_607621 != nil:
    section.add "X-Amz-Credential", valid_607621
  var valid_607622 = header.getOrDefault("X-Amz-Security-Token")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "X-Amz-Security-Token", valid_607622
  var valid_607623 = header.getOrDefault("X-Amz-Algorithm")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Algorithm", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-SignedHeaders", valid_607624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607626: Call_UpdateRestApi_607614; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_607626.validator(path, query, header, formData, body)
  let scheme = call_607626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607626.url(scheme.get, call_607626.host, call_607626.base,
                         call_607626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607626, url, valid)

proc call*(call_607627: Call_UpdateRestApi_607614; restapiId: string; body: JsonNode): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_607628 = newJObject()
  var body_607629 = newJObject()
  add(path_607628, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607629 = body
  result = call_607627.call(path_607628, nil, nil, nil, body_607629)

var updateRestApi* = Call_UpdateRestApi_607614(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_607615,
    base: "/", url: url_UpdateRestApi_607616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_607600 = ref object of OpenApiRestCall_605573
proc url_DeleteRestApi_607602(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRestApi_607601(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607603 = path.getOrDefault("restapi_id")
  valid_607603 = validateParameter(valid_607603, JString, required = true,
                                 default = nil)
  if valid_607603 != nil:
    section.add "restapi_id", valid_607603
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607604 = header.getOrDefault("X-Amz-Signature")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-Signature", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Content-Sha256", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Date")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Date", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-Credential")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Credential", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Security-Token")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Security-Token", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-Algorithm")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Algorithm", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-SignedHeaders", valid_607610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607611: Call_DeleteRestApi_607600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_607611.validator(path, query, header, formData, body)
  let scheme = call_607611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607611.url(scheme.get, call_607611.host, call_607611.base,
                         call_607611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607611, url, valid)

proc call*(call_607612: Call_DeleteRestApi_607600; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_607613 = newJObject()
  add(path_607613, "restapi_id", newJString(restapiId))
  result = call_607612.call(path_607613, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_607600(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_607601,
    base: "/", url: url_DeleteRestApi_607602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_607630 = ref object of OpenApiRestCall_605573
proc url_GetStage_607632(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_607631(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607633 = path.getOrDefault("restapi_id")
  valid_607633 = validateParameter(valid_607633, JString, required = true,
                                 default = nil)
  if valid_607633 != nil:
    section.add "restapi_id", valid_607633
  var valid_607634 = path.getOrDefault("stage_name")
  valid_607634 = validateParameter(valid_607634, JString, required = true,
                                 default = nil)
  if valid_607634 != nil:
    section.add "stage_name", valid_607634
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607635 = header.getOrDefault("X-Amz-Signature")
  valid_607635 = validateParameter(valid_607635, JString, required = false,
                                 default = nil)
  if valid_607635 != nil:
    section.add "X-Amz-Signature", valid_607635
  var valid_607636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607636 = validateParameter(valid_607636, JString, required = false,
                                 default = nil)
  if valid_607636 != nil:
    section.add "X-Amz-Content-Sha256", valid_607636
  var valid_607637 = header.getOrDefault("X-Amz-Date")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "X-Amz-Date", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-Credential")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-Credential", valid_607638
  var valid_607639 = header.getOrDefault("X-Amz-Security-Token")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Security-Token", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Algorithm")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Algorithm", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-SignedHeaders", valid_607641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607642: Call_GetStage_607630; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_607642.validator(path, query, header, formData, body)
  let scheme = call_607642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607642.url(scheme.get, call_607642.host, call_607642.base,
                         call_607642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607642, url, valid)

proc call*(call_607643: Call_GetStage_607630; restapiId: string; stageName: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  var path_607644 = newJObject()
  add(path_607644, "restapi_id", newJString(restapiId))
  add(path_607644, "stage_name", newJString(stageName))
  result = call_607643.call(path_607644, nil, nil, nil, nil)

var getStage* = Call_GetStage_607630(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_607631, base: "/",
                                  url: url_GetStage_607632,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_607660 = ref object of OpenApiRestCall_605573
proc url_UpdateStage_607662(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_607661(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607663 = path.getOrDefault("restapi_id")
  valid_607663 = validateParameter(valid_607663, JString, required = true,
                                 default = nil)
  if valid_607663 != nil:
    section.add "restapi_id", valid_607663
  var valid_607664 = path.getOrDefault("stage_name")
  valid_607664 = validateParameter(valid_607664, JString, required = true,
                                 default = nil)
  if valid_607664 != nil:
    section.add "stage_name", valid_607664
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607665 = header.getOrDefault("X-Amz-Signature")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-Signature", valid_607665
  var valid_607666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607666 = validateParameter(valid_607666, JString, required = false,
                                 default = nil)
  if valid_607666 != nil:
    section.add "X-Amz-Content-Sha256", valid_607666
  var valid_607667 = header.getOrDefault("X-Amz-Date")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "X-Amz-Date", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-Credential")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-Credential", valid_607668
  var valid_607669 = header.getOrDefault("X-Amz-Security-Token")
  valid_607669 = validateParameter(valid_607669, JString, required = false,
                                 default = nil)
  if valid_607669 != nil:
    section.add "X-Amz-Security-Token", valid_607669
  var valid_607670 = header.getOrDefault("X-Amz-Algorithm")
  valid_607670 = validateParameter(valid_607670, JString, required = false,
                                 default = nil)
  if valid_607670 != nil:
    section.add "X-Amz-Algorithm", valid_607670
  var valid_607671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "X-Amz-SignedHeaders", valid_607671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607673: Call_UpdateStage_607660; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_607673.validator(path, query, header, formData, body)
  let scheme = call_607673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607673.url(scheme.get, call_607673.host, call_607673.base,
                         call_607673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607673, url, valid)

proc call*(call_607674: Call_UpdateStage_607660; restapiId: string; body: JsonNode;
          stageName: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  var path_607675 = newJObject()
  var body_607676 = newJObject()
  add(path_607675, "restapi_id", newJString(restapiId))
  if body != nil:
    body_607676 = body
  add(path_607675, "stage_name", newJString(stageName))
  result = call_607674.call(path_607675, nil, nil, nil, body_607676)

var updateStage* = Call_UpdateStage_607660(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_607661,
                                        base: "/", url: url_UpdateStage_607662,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_607645 = ref object of OpenApiRestCall_605573
proc url_DeleteStage_607647(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_607646(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607648 = path.getOrDefault("restapi_id")
  valid_607648 = validateParameter(valid_607648, JString, required = true,
                                 default = nil)
  if valid_607648 != nil:
    section.add "restapi_id", valid_607648
  var valid_607649 = path.getOrDefault("stage_name")
  valid_607649 = validateParameter(valid_607649, JString, required = true,
                                 default = nil)
  if valid_607649 != nil:
    section.add "stage_name", valid_607649
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607650 = header.getOrDefault("X-Amz-Signature")
  valid_607650 = validateParameter(valid_607650, JString, required = false,
                                 default = nil)
  if valid_607650 != nil:
    section.add "X-Amz-Signature", valid_607650
  var valid_607651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607651 = validateParameter(valid_607651, JString, required = false,
                                 default = nil)
  if valid_607651 != nil:
    section.add "X-Amz-Content-Sha256", valid_607651
  var valid_607652 = header.getOrDefault("X-Amz-Date")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "X-Amz-Date", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-Credential")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-Credential", valid_607653
  var valid_607654 = header.getOrDefault("X-Amz-Security-Token")
  valid_607654 = validateParameter(valid_607654, JString, required = false,
                                 default = nil)
  if valid_607654 != nil:
    section.add "X-Amz-Security-Token", valid_607654
  var valid_607655 = header.getOrDefault("X-Amz-Algorithm")
  valid_607655 = validateParameter(valid_607655, JString, required = false,
                                 default = nil)
  if valid_607655 != nil:
    section.add "X-Amz-Algorithm", valid_607655
  var valid_607656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-SignedHeaders", valid_607656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607657: Call_DeleteStage_607645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_607657.validator(path, query, header, formData, body)
  let scheme = call_607657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607657.url(scheme.get, call_607657.host, call_607657.base,
                         call_607657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607657, url, valid)

proc call*(call_607658: Call_DeleteStage_607645; restapiId: string; stageName: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  var path_607659 = newJObject()
  add(path_607659, "restapi_id", newJString(restapiId))
  add(path_607659, "stage_name", newJString(stageName))
  result = call_607658.call(path_607659, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_607645(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_607646,
                                        base: "/", url: url_DeleteStage_607647,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_607677 = ref object of OpenApiRestCall_605573
proc url_GetUsagePlan_607679(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlan_607678(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607680 = path.getOrDefault("usageplanId")
  valid_607680 = validateParameter(valid_607680, JString, required = true,
                                 default = nil)
  if valid_607680 != nil:
    section.add "usageplanId", valid_607680
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607681 = header.getOrDefault("X-Amz-Signature")
  valid_607681 = validateParameter(valid_607681, JString, required = false,
                                 default = nil)
  if valid_607681 != nil:
    section.add "X-Amz-Signature", valid_607681
  var valid_607682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "X-Amz-Content-Sha256", valid_607682
  var valid_607683 = header.getOrDefault("X-Amz-Date")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "X-Amz-Date", valid_607683
  var valid_607684 = header.getOrDefault("X-Amz-Credential")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "X-Amz-Credential", valid_607684
  var valid_607685 = header.getOrDefault("X-Amz-Security-Token")
  valid_607685 = validateParameter(valid_607685, JString, required = false,
                                 default = nil)
  if valid_607685 != nil:
    section.add "X-Amz-Security-Token", valid_607685
  var valid_607686 = header.getOrDefault("X-Amz-Algorithm")
  valid_607686 = validateParameter(valid_607686, JString, required = false,
                                 default = nil)
  if valid_607686 != nil:
    section.add "X-Amz-Algorithm", valid_607686
  var valid_607687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607687 = validateParameter(valid_607687, JString, required = false,
                                 default = nil)
  if valid_607687 != nil:
    section.add "X-Amz-SignedHeaders", valid_607687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607688: Call_GetUsagePlan_607677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_607688.validator(path, query, header, formData, body)
  let scheme = call_607688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607688.url(scheme.get, call_607688.host, call_607688.base,
                         call_607688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607688, url, valid)

proc call*(call_607689: Call_GetUsagePlan_607677; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_607690 = newJObject()
  add(path_607690, "usageplanId", newJString(usageplanId))
  result = call_607689.call(path_607690, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_607677(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_607678,
    base: "/", url: url_GetUsagePlan_607679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_607705 = ref object of OpenApiRestCall_605573
proc url_UpdateUsagePlan_607707(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsagePlan_607706(path: JsonNode; query: JsonNode;
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
  var valid_607708 = path.getOrDefault("usageplanId")
  valid_607708 = validateParameter(valid_607708, JString, required = true,
                                 default = nil)
  if valid_607708 != nil:
    section.add "usageplanId", valid_607708
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607709 = header.getOrDefault("X-Amz-Signature")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Signature", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Content-Sha256", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Date")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Date", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Credential")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Credential", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Security-Token")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Security-Token", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Algorithm")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Algorithm", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-SignedHeaders", valid_607715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607717: Call_UpdateUsagePlan_607705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_607717.validator(path, query, header, formData, body)
  let scheme = call_607717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607717.url(scheme.get, call_607717.host, call_607717.base,
                         call_607717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607717, url, valid)

proc call*(call_607718: Call_UpdateUsagePlan_607705; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_607719 = newJObject()
  var body_607720 = newJObject()
  add(path_607719, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_607720 = body
  result = call_607718.call(path_607719, nil, nil, nil, body_607720)

var updateUsagePlan* = Call_UpdateUsagePlan_607705(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_607706,
    base: "/", url: url_UpdateUsagePlan_607707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_607691 = ref object of OpenApiRestCall_605573
proc url_DeleteUsagePlan_607693(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlan_607692(path: JsonNode; query: JsonNode;
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
  var valid_607694 = path.getOrDefault("usageplanId")
  valid_607694 = validateParameter(valid_607694, JString, required = true,
                                 default = nil)
  if valid_607694 != nil:
    section.add "usageplanId", valid_607694
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607695 = header.getOrDefault("X-Amz-Signature")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Signature", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Content-Sha256", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-Date")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Date", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Credential")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Credential", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Security-Token")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Security-Token", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Algorithm")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Algorithm", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-SignedHeaders", valid_607701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607702: Call_DeleteUsagePlan_607691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_607702.validator(path, query, header, formData, body)
  let scheme = call_607702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607702.url(scheme.get, call_607702.host, call_607702.base,
                         call_607702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607702, url, valid)

proc call*(call_607703: Call_DeleteUsagePlan_607691; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_607704 = newJObject()
  add(path_607704, "usageplanId", newJString(usageplanId))
  result = call_607703.call(path_607704, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_607691(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_607692,
    base: "/", url: url_DeleteUsagePlan_607693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_607721 = ref object of OpenApiRestCall_605573
proc url_GetUsagePlanKey_607723(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKey_607722(path: JsonNode; query: JsonNode;
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
  var valid_607724 = path.getOrDefault("usageplanId")
  valid_607724 = validateParameter(valid_607724, JString, required = true,
                                 default = nil)
  if valid_607724 != nil:
    section.add "usageplanId", valid_607724
  var valid_607725 = path.getOrDefault("keyId")
  valid_607725 = validateParameter(valid_607725, JString, required = true,
                                 default = nil)
  if valid_607725 != nil:
    section.add "keyId", valid_607725
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607726 = header.getOrDefault("X-Amz-Signature")
  valid_607726 = validateParameter(valid_607726, JString, required = false,
                                 default = nil)
  if valid_607726 != nil:
    section.add "X-Amz-Signature", valid_607726
  var valid_607727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "X-Amz-Content-Sha256", valid_607727
  var valid_607728 = header.getOrDefault("X-Amz-Date")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "X-Amz-Date", valid_607728
  var valid_607729 = header.getOrDefault("X-Amz-Credential")
  valid_607729 = validateParameter(valid_607729, JString, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "X-Amz-Credential", valid_607729
  var valid_607730 = header.getOrDefault("X-Amz-Security-Token")
  valid_607730 = validateParameter(valid_607730, JString, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "X-Amz-Security-Token", valid_607730
  var valid_607731 = header.getOrDefault("X-Amz-Algorithm")
  valid_607731 = validateParameter(valid_607731, JString, required = false,
                                 default = nil)
  if valid_607731 != nil:
    section.add "X-Amz-Algorithm", valid_607731
  var valid_607732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607732 = validateParameter(valid_607732, JString, required = false,
                                 default = nil)
  if valid_607732 != nil:
    section.add "X-Amz-SignedHeaders", valid_607732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607733: Call_GetUsagePlanKey_607721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_607733.validator(path, query, header, formData, body)
  let scheme = call_607733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607733.url(scheme.get, call_607733.host, call_607733.base,
                         call_607733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607733, url, valid)

proc call*(call_607734: Call_GetUsagePlanKey_607721; usageplanId: string;
          keyId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_607735 = newJObject()
  add(path_607735, "usageplanId", newJString(usageplanId))
  add(path_607735, "keyId", newJString(keyId))
  result = call_607734.call(path_607735, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_607721(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_607722, base: "/", url: url_GetUsagePlanKey_607723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_607736 = ref object of OpenApiRestCall_605573
proc url_DeleteUsagePlanKey_607738(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlanKey_607737(path: JsonNode; query: JsonNode;
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
  var valid_607739 = path.getOrDefault("usageplanId")
  valid_607739 = validateParameter(valid_607739, JString, required = true,
                                 default = nil)
  if valid_607739 != nil:
    section.add "usageplanId", valid_607739
  var valid_607740 = path.getOrDefault("keyId")
  valid_607740 = validateParameter(valid_607740, JString, required = true,
                                 default = nil)
  if valid_607740 != nil:
    section.add "keyId", valid_607740
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607741 = header.getOrDefault("X-Amz-Signature")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Signature", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Content-Sha256", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-Date")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Date", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-Credential")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-Credential", valid_607744
  var valid_607745 = header.getOrDefault("X-Amz-Security-Token")
  valid_607745 = validateParameter(valid_607745, JString, required = false,
                                 default = nil)
  if valid_607745 != nil:
    section.add "X-Amz-Security-Token", valid_607745
  var valid_607746 = header.getOrDefault("X-Amz-Algorithm")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-Algorithm", valid_607746
  var valid_607747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607747 = validateParameter(valid_607747, JString, required = false,
                                 default = nil)
  if valid_607747 != nil:
    section.add "X-Amz-SignedHeaders", valid_607747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607748: Call_DeleteUsagePlanKey_607736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_607748.validator(path, query, header, formData, body)
  let scheme = call_607748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607748.url(scheme.get, call_607748.host, call_607748.base,
                         call_607748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607748, url, valid)

proc call*(call_607749: Call_DeleteUsagePlanKey_607736; usageplanId: string;
          keyId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  var path_607750 = newJObject()
  add(path_607750, "usageplanId", newJString(usageplanId))
  add(path_607750, "keyId", newJString(keyId))
  result = call_607749.call(path_607750, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_607736(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_607737, base: "/",
    url: url_DeleteUsagePlanKey_607738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_607751 = ref object of OpenApiRestCall_605573
proc url_GetVpcLink_607753(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetVpcLink_607752(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607754 = path.getOrDefault("vpclink_id")
  valid_607754 = validateParameter(valid_607754, JString, required = true,
                                 default = nil)
  if valid_607754 != nil:
    section.add "vpclink_id", valid_607754
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607755 = header.getOrDefault("X-Amz-Signature")
  valid_607755 = validateParameter(valid_607755, JString, required = false,
                                 default = nil)
  if valid_607755 != nil:
    section.add "X-Amz-Signature", valid_607755
  var valid_607756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Content-Sha256", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-Date")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-Date", valid_607757
  var valid_607758 = header.getOrDefault("X-Amz-Credential")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Credential", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-Security-Token")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-Security-Token", valid_607759
  var valid_607760 = header.getOrDefault("X-Amz-Algorithm")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "X-Amz-Algorithm", valid_607760
  var valid_607761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607761 = validateParameter(valid_607761, JString, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "X-Amz-SignedHeaders", valid_607761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607762: Call_GetVpcLink_607751; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_607762.validator(path, query, header, formData, body)
  let scheme = call_607762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607762.url(scheme.get, call_607762.host, call_607762.base,
                         call_607762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607762, url, valid)

proc call*(call_607763: Call_GetVpcLink_607751; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_607764 = newJObject()
  add(path_607764, "vpclink_id", newJString(vpclinkId))
  result = call_607763.call(path_607764, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_607751(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_607752,
                                      base: "/", url: url_GetVpcLink_607753,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_607779 = ref object of OpenApiRestCall_605573
proc url_UpdateVpcLink_607781(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVpcLink_607780(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607782 = path.getOrDefault("vpclink_id")
  valid_607782 = validateParameter(valid_607782, JString, required = true,
                                 default = nil)
  if valid_607782 != nil:
    section.add "vpclink_id", valid_607782
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607783 = header.getOrDefault("X-Amz-Signature")
  valid_607783 = validateParameter(valid_607783, JString, required = false,
                                 default = nil)
  if valid_607783 != nil:
    section.add "X-Amz-Signature", valid_607783
  var valid_607784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607784 = validateParameter(valid_607784, JString, required = false,
                                 default = nil)
  if valid_607784 != nil:
    section.add "X-Amz-Content-Sha256", valid_607784
  var valid_607785 = header.getOrDefault("X-Amz-Date")
  valid_607785 = validateParameter(valid_607785, JString, required = false,
                                 default = nil)
  if valid_607785 != nil:
    section.add "X-Amz-Date", valid_607785
  var valid_607786 = header.getOrDefault("X-Amz-Credential")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Credential", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-Security-Token")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-Security-Token", valid_607787
  var valid_607788 = header.getOrDefault("X-Amz-Algorithm")
  valid_607788 = validateParameter(valid_607788, JString, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "X-Amz-Algorithm", valid_607788
  var valid_607789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-SignedHeaders", valid_607789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607791: Call_UpdateVpcLink_607779; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_607791.validator(path, query, header, formData, body)
  let scheme = call_607791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607791.url(scheme.get, call_607791.host, call_607791.base,
                         call_607791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607791, url, valid)

proc call*(call_607792: Call_UpdateVpcLink_607779; vpclinkId: string; body: JsonNode): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  ##   body: JObject (required)
  var path_607793 = newJObject()
  var body_607794 = newJObject()
  add(path_607793, "vpclink_id", newJString(vpclinkId))
  if body != nil:
    body_607794 = body
  result = call_607792.call(path_607793, nil, nil, nil, body_607794)

var updateVpcLink* = Call_UpdateVpcLink_607779(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_607780,
    base: "/", url: url_UpdateVpcLink_607781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_607765 = ref object of OpenApiRestCall_605573
proc url_DeleteVpcLink_607767(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVpcLink_607766(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607768 = path.getOrDefault("vpclink_id")
  valid_607768 = validateParameter(valid_607768, JString, required = true,
                                 default = nil)
  if valid_607768 != nil:
    section.add "vpclink_id", valid_607768
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607769 = header.getOrDefault("X-Amz-Signature")
  valid_607769 = validateParameter(valid_607769, JString, required = false,
                                 default = nil)
  if valid_607769 != nil:
    section.add "X-Amz-Signature", valid_607769
  var valid_607770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "X-Amz-Content-Sha256", valid_607770
  var valid_607771 = header.getOrDefault("X-Amz-Date")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "X-Amz-Date", valid_607771
  var valid_607772 = header.getOrDefault("X-Amz-Credential")
  valid_607772 = validateParameter(valid_607772, JString, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "X-Amz-Credential", valid_607772
  var valid_607773 = header.getOrDefault("X-Amz-Security-Token")
  valid_607773 = validateParameter(valid_607773, JString, required = false,
                                 default = nil)
  if valid_607773 != nil:
    section.add "X-Amz-Security-Token", valid_607773
  var valid_607774 = header.getOrDefault("X-Amz-Algorithm")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-Algorithm", valid_607774
  var valid_607775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "X-Amz-SignedHeaders", valid_607775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607776: Call_DeleteVpcLink_607765; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_607776.validator(path, query, header, formData, body)
  let scheme = call_607776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607776.url(scheme.get, call_607776.host, call_607776.base,
                         call_607776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607776, url, valid)

proc call*(call_607777: Call_DeleteVpcLink_607765; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_607778 = newJObject()
  add(path_607778, "vpclink_id", newJString(vpclinkId))
  result = call_607777.call(path_607778, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_607765(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_607766,
    base: "/", url: url_DeleteVpcLink_607767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_607795 = ref object of OpenApiRestCall_605573
proc url_FlushStageAuthorizersCache_607797(protocol: Scheme; host: string;
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

proc validate_FlushStageAuthorizersCache_607796(path: JsonNode; query: JsonNode;
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
  var valid_607798 = path.getOrDefault("restapi_id")
  valid_607798 = validateParameter(valid_607798, JString, required = true,
                                 default = nil)
  if valid_607798 != nil:
    section.add "restapi_id", valid_607798
  var valid_607799 = path.getOrDefault("stage_name")
  valid_607799 = validateParameter(valid_607799, JString, required = true,
                                 default = nil)
  if valid_607799 != nil:
    section.add "stage_name", valid_607799
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607800 = header.getOrDefault("X-Amz-Signature")
  valid_607800 = validateParameter(valid_607800, JString, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "X-Amz-Signature", valid_607800
  var valid_607801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607801 = validateParameter(valid_607801, JString, required = false,
                                 default = nil)
  if valid_607801 != nil:
    section.add "X-Amz-Content-Sha256", valid_607801
  var valid_607802 = header.getOrDefault("X-Amz-Date")
  valid_607802 = validateParameter(valid_607802, JString, required = false,
                                 default = nil)
  if valid_607802 != nil:
    section.add "X-Amz-Date", valid_607802
  var valid_607803 = header.getOrDefault("X-Amz-Credential")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Credential", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-Security-Token")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-Security-Token", valid_607804
  var valid_607805 = header.getOrDefault("X-Amz-Algorithm")
  valid_607805 = validateParameter(valid_607805, JString, required = false,
                                 default = nil)
  if valid_607805 != nil:
    section.add "X-Amz-Algorithm", valid_607805
  var valid_607806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607806 = validateParameter(valid_607806, JString, required = false,
                                 default = nil)
  if valid_607806 != nil:
    section.add "X-Amz-SignedHeaders", valid_607806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607807: Call_FlushStageAuthorizersCache_607795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_607807.validator(path, query, header, formData, body)
  let scheme = call_607807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607807.url(scheme.get, call_607807.host, call_607807.base,
                         call_607807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607807, url, valid)

proc call*(call_607808: Call_FlushStageAuthorizersCache_607795; restapiId: string;
          stageName: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  var path_607809 = newJObject()
  add(path_607809, "restapi_id", newJString(restapiId))
  add(path_607809, "stage_name", newJString(stageName))
  result = call_607808.call(path_607809, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_607795(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_607796, base: "/",
    url: url_FlushStageAuthorizersCache_607797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_607810 = ref object of OpenApiRestCall_605573
proc url_FlushStageCache_607812(protocol: Scheme; host: string; base: string;
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

proc validate_FlushStageCache_607811(path: JsonNode; query: JsonNode;
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
  var valid_607813 = path.getOrDefault("restapi_id")
  valid_607813 = validateParameter(valid_607813, JString, required = true,
                                 default = nil)
  if valid_607813 != nil:
    section.add "restapi_id", valid_607813
  var valid_607814 = path.getOrDefault("stage_name")
  valid_607814 = validateParameter(valid_607814, JString, required = true,
                                 default = nil)
  if valid_607814 != nil:
    section.add "stage_name", valid_607814
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607815 = header.getOrDefault("X-Amz-Signature")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-Signature", valid_607815
  var valid_607816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = nil)
  if valid_607816 != nil:
    section.add "X-Amz-Content-Sha256", valid_607816
  var valid_607817 = header.getOrDefault("X-Amz-Date")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "X-Amz-Date", valid_607817
  var valid_607818 = header.getOrDefault("X-Amz-Credential")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Credential", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-Security-Token")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-Security-Token", valid_607819
  var valid_607820 = header.getOrDefault("X-Amz-Algorithm")
  valid_607820 = validateParameter(valid_607820, JString, required = false,
                                 default = nil)
  if valid_607820 != nil:
    section.add "X-Amz-Algorithm", valid_607820
  var valid_607821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607821 = validateParameter(valid_607821, JString, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "X-Amz-SignedHeaders", valid_607821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607822: Call_FlushStageCache_607810; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_607822.validator(path, query, header, formData, body)
  let scheme = call_607822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607822.url(scheme.get, call_607822.host, call_607822.base,
                         call_607822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607822, url, valid)

proc call*(call_607823: Call_FlushStageCache_607810; restapiId: string;
          stageName: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  var path_607824 = newJObject()
  add(path_607824, "restapi_id", newJString(restapiId))
  add(path_607824, "stage_name", newJString(stageName))
  result = call_607823.call(path_607824, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_607810(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_607811, base: "/", url: url_FlushStageCache_607812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_607840 = ref object of OpenApiRestCall_605573
proc url_GenerateClientCertificate_607842(protocol: Scheme; host: string;
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

proc validate_GenerateClientCertificate_607841(path: JsonNode; query: JsonNode;
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
  var valid_607843 = header.getOrDefault("X-Amz-Signature")
  valid_607843 = validateParameter(valid_607843, JString, required = false,
                                 default = nil)
  if valid_607843 != nil:
    section.add "X-Amz-Signature", valid_607843
  var valid_607844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607844 = validateParameter(valid_607844, JString, required = false,
                                 default = nil)
  if valid_607844 != nil:
    section.add "X-Amz-Content-Sha256", valid_607844
  var valid_607845 = header.getOrDefault("X-Amz-Date")
  valid_607845 = validateParameter(valid_607845, JString, required = false,
                                 default = nil)
  if valid_607845 != nil:
    section.add "X-Amz-Date", valid_607845
  var valid_607846 = header.getOrDefault("X-Amz-Credential")
  valid_607846 = validateParameter(valid_607846, JString, required = false,
                                 default = nil)
  if valid_607846 != nil:
    section.add "X-Amz-Credential", valid_607846
  var valid_607847 = header.getOrDefault("X-Amz-Security-Token")
  valid_607847 = validateParameter(valid_607847, JString, required = false,
                                 default = nil)
  if valid_607847 != nil:
    section.add "X-Amz-Security-Token", valid_607847
  var valid_607848 = header.getOrDefault("X-Amz-Algorithm")
  valid_607848 = validateParameter(valid_607848, JString, required = false,
                                 default = nil)
  if valid_607848 != nil:
    section.add "X-Amz-Algorithm", valid_607848
  var valid_607849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-SignedHeaders", valid_607849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607851: Call_GenerateClientCertificate_607840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_607851.validator(path, query, header, formData, body)
  let scheme = call_607851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607851.url(scheme.get, call_607851.host, call_607851.base,
                         call_607851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607851, url, valid)

proc call*(call_607852: Call_GenerateClientCertificate_607840; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_607853 = newJObject()
  if body != nil:
    body_607853 = body
  result = call_607852.call(nil, nil, nil, nil, body_607853)

var generateClientCertificate* = Call_GenerateClientCertificate_607840(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_607841, base: "/",
    url: url_GenerateClientCertificate_607842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_607825 = ref object of OpenApiRestCall_605573
proc url_GetClientCertificates_607827(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificates_607826(path: JsonNode; query: JsonNode;
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
  var valid_607828 = query.getOrDefault("limit")
  valid_607828 = validateParameter(valid_607828, JInt, required = false, default = nil)
  if valid_607828 != nil:
    section.add "limit", valid_607828
  var valid_607829 = query.getOrDefault("position")
  valid_607829 = validateParameter(valid_607829, JString, required = false,
                                 default = nil)
  if valid_607829 != nil:
    section.add "position", valid_607829
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607830 = header.getOrDefault("X-Amz-Signature")
  valid_607830 = validateParameter(valid_607830, JString, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "X-Amz-Signature", valid_607830
  var valid_607831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607831 = validateParameter(valid_607831, JString, required = false,
                                 default = nil)
  if valid_607831 != nil:
    section.add "X-Amz-Content-Sha256", valid_607831
  var valid_607832 = header.getOrDefault("X-Amz-Date")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "X-Amz-Date", valid_607832
  var valid_607833 = header.getOrDefault("X-Amz-Credential")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "X-Amz-Credential", valid_607833
  var valid_607834 = header.getOrDefault("X-Amz-Security-Token")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-Security-Token", valid_607834
  var valid_607835 = header.getOrDefault("X-Amz-Algorithm")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Algorithm", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-SignedHeaders", valid_607836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607837: Call_GetClientCertificates_607825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_607837.validator(path, query, header, formData, body)
  let scheme = call_607837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607837.url(scheme.get, call_607837.host, call_607837.base,
                         call_607837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607837, url, valid)

proc call*(call_607838: Call_GetClientCertificates_607825; limit: int = 0;
          position: string = ""): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_607839 = newJObject()
  add(query_607839, "limit", newJInt(limit))
  add(query_607839, "position", newJString(position))
  result = call_607838.call(nil, query_607839, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_607825(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_607826, base: "/",
    url: url_GetClientCertificates_607827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_607854 = ref object of OpenApiRestCall_605573
proc url_GetAccount_607856(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_607855(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607857 = header.getOrDefault("X-Amz-Signature")
  valid_607857 = validateParameter(valid_607857, JString, required = false,
                                 default = nil)
  if valid_607857 != nil:
    section.add "X-Amz-Signature", valid_607857
  var valid_607858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607858 = validateParameter(valid_607858, JString, required = false,
                                 default = nil)
  if valid_607858 != nil:
    section.add "X-Amz-Content-Sha256", valid_607858
  var valid_607859 = header.getOrDefault("X-Amz-Date")
  valid_607859 = validateParameter(valid_607859, JString, required = false,
                                 default = nil)
  if valid_607859 != nil:
    section.add "X-Amz-Date", valid_607859
  var valid_607860 = header.getOrDefault("X-Amz-Credential")
  valid_607860 = validateParameter(valid_607860, JString, required = false,
                                 default = nil)
  if valid_607860 != nil:
    section.add "X-Amz-Credential", valid_607860
  var valid_607861 = header.getOrDefault("X-Amz-Security-Token")
  valid_607861 = validateParameter(valid_607861, JString, required = false,
                                 default = nil)
  if valid_607861 != nil:
    section.add "X-Amz-Security-Token", valid_607861
  var valid_607862 = header.getOrDefault("X-Amz-Algorithm")
  valid_607862 = validateParameter(valid_607862, JString, required = false,
                                 default = nil)
  if valid_607862 != nil:
    section.add "X-Amz-Algorithm", valid_607862
  var valid_607863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607863 = validateParameter(valid_607863, JString, required = false,
                                 default = nil)
  if valid_607863 != nil:
    section.add "X-Amz-SignedHeaders", valid_607863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607864: Call_GetAccount_607854; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_607864.validator(path, query, header, formData, body)
  let scheme = call_607864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607864.url(scheme.get, call_607864.host, call_607864.base,
                         call_607864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607864, url, valid)

proc call*(call_607865: Call_GetAccount_607854): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_607865.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_607854(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_607855,
                                      base: "/", url: url_GetAccount_607856,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_607866 = ref object of OpenApiRestCall_605573
proc url_UpdateAccount_607868(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_607867(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607869 = header.getOrDefault("X-Amz-Signature")
  valid_607869 = validateParameter(valid_607869, JString, required = false,
                                 default = nil)
  if valid_607869 != nil:
    section.add "X-Amz-Signature", valid_607869
  var valid_607870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607870 = validateParameter(valid_607870, JString, required = false,
                                 default = nil)
  if valid_607870 != nil:
    section.add "X-Amz-Content-Sha256", valid_607870
  var valid_607871 = header.getOrDefault("X-Amz-Date")
  valid_607871 = validateParameter(valid_607871, JString, required = false,
                                 default = nil)
  if valid_607871 != nil:
    section.add "X-Amz-Date", valid_607871
  var valid_607872 = header.getOrDefault("X-Amz-Credential")
  valid_607872 = validateParameter(valid_607872, JString, required = false,
                                 default = nil)
  if valid_607872 != nil:
    section.add "X-Amz-Credential", valid_607872
  var valid_607873 = header.getOrDefault("X-Amz-Security-Token")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "X-Amz-Security-Token", valid_607873
  var valid_607874 = header.getOrDefault("X-Amz-Algorithm")
  valid_607874 = validateParameter(valid_607874, JString, required = false,
                                 default = nil)
  if valid_607874 != nil:
    section.add "X-Amz-Algorithm", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-SignedHeaders", valid_607875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607877: Call_UpdateAccount_607866; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_607877.validator(path, query, header, formData, body)
  let scheme = call_607877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607877.url(scheme.get, call_607877.host, call_607877.base,
                         call_607877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607877, url, valid)

proc call*(call_607878: Call_UpdateAccount_607866; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_607879 = newJObject()
  if body != nil:
    body_607879 = body
  result = call_607878.call(nil, nil, nil, nil, body_607879)

var updateAccount* = Call_UpdateAccount_607866(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_607867, base: "/", url: url_UpdateAccount_607868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_607880 = ref object of OpenApiRestCall_605573
proc url_GetExport_607882(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetExport_607881(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607883 = path.getOrDefault("export_type")
  valid_607883 = validateParameter(valid_607883, JString, required = true,
                                 default = nil)
  if valid_607883 != nil:
    section.add "export_type", valid_607883
  var valid_607884 = path.getOrDefault("restapi_id")
  valid_607884 = validateParameter(valid_607884, JString, required = true,
                                 default = nil)
  if valid_607884 != nil:
    section.add "restapi_id", valid_607884
  var valid_607885 = path.getOrDefault("stage_name")
  valid_607885 = validateParameter(valid_607885, JString, required = true,
                                 default = nil)
  if valid_607885 != nil:
    section.add "stage_name", valid_607885
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_607886 = query.getOrDefault("parameters.2.value")
  valid_607886 = validateParameter(valid_607886, JString, required = false,
                                 default = nil)
  if valid_607886 != nil:
    section.add "parameters.2.value", valid_607886
  var valid_607887 = query.getOrDefault("parameters.1.value")
  valid_607887 = validateParameter(valid_607887, JString, required = false,
                                 default = nil)
  if valid_607887 != nil:
    section.add "parameters.1.value", valid_607887
  var valid_607888 = query.getOrDefault("parameters.1.key")
  valid_607888 = validateParameter(valid_607888, JString, required = false,
                                 default = nil)
  if valid_607888 != nil:
    section.add "parameters.1.key", valid_607888
  var valid_607889 = query.getOrDefault("parameters.2.key")
  valid_607889 = validateParameter(valid_607889, JString, required = false,
                                 default = nil)
  if valid_607889 != nil:
    section.add "parameters.2.key", valid_607889
  var valid_607890 = query.getOrDefault("parameters.0.value")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "parameters.0.value", valid_607890
  var valid_607891 = query.getOrDefault("parameters.0.key")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "parameters.0.key", valid_607891
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
  var valid_607892 = header.getOrDefault("X-Amz-Signature")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-Signature", valid_607892
  var valid_607893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607893 = validateParameter(valid_607893, JString, required = false,
                                 default = nil)
  if valid_607893 != nil:
    section.add "X-Amz-Content-Sha256", valid_607893
  var valid_607894 = header.getOrDefault("X-Amz-Date")
  valid_607894 = validateParameter(valid_607894, JString, required = false,
                                 default = nil)
  if valid_607894 != nil:
    section.add "X-Amz-Date", valid_607894
  var valid_607895 = header.getOrDefault("X-Amz-Credential")
  valid_607895 = validateParameter(valid_607895, JString, required = false,
                                 default = nil)
  if valid_607895 != nil:
    section.add "X-Amz-Credential", valid_607895
  var valid_607896 = header.getOrDefault("X-Amz-Security-Token")
  valid_607896 = validateParameter(valid_607896, JString, required = false,
                                 default = nil)
  if valid_607896 != nil:
    section.add "X-Amz-Security-Token", valid_607896
  var valid_607897 = header.getOrDefault("X-Amz-Algorithm")
  valid_607897 = validateParameter(valid_607897, JString, required = false,
                                 default = nil)
  if valid_607897 != nil:
    section.add "X-Amz-Algorithm", valid_607897
  var valid_607898 = header.getOrDefault("Accept")
  valid_607898 = validateParameter(valid_607898, JString, required = false,
                                 default = nil)
  if valid_607898 != nil:
    section.add "Accept", valid_607898
  var valid_607899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607899 = validateParameter(valid_607899, JString, required = false,
                                 default = nil)
  if valid_607899 != nil:
    section.add "X-Amz-SignedHeaders", valid_607899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607900: Call_GetExport_607880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_607900.validator(path, query, header, formData, body)
  let scheme = call_607900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607900.url(scheme.get, call_607900.host, call_607900.base,
                         call_607900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607900, url, valid)

proc call*(call_607901: Call_GetExport_607880; exportType: string; restapiId: string;
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
  var path_607902 = newJObject()
  var query_607903 = newJObject()
  add(query_607903, "parameters.2.value", newJString(parameters2Value))
  add(query_607903, "parameters.1.value", newJString(parameters1Value))
  add(query_607903, "parameters.1.key", newJString(parameters1Key))
  add(path_607902, "export_type", newJString(exportType))
  add(path_607902, "restapi_id", newJString(restapiId))
  add(query_607903, "parameters.2.key", newJString(parameters2Key))
  add(path_607902, "stage_name", newJString(stageName))
  add(query_607903, "parameters.0.value", newJString(parameters0Value))
  add(query_607903, "parameters.0.key", newJString(parameters0Key))
  result = call_607901.call(path_607902, query_607903, nil, nil, nil)

var getExport* = Call_GetExport_607880(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_607881,
                                    base: "/", url: url_GetExport_607882,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_607904 = ref object of OpenApiRestCall_605573
proc url_GetGatewayResponses_607906(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponses_607905(path: JsonNode; query: JsonNode;
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
  var valid_607907 = path.getOrDefault("restapi_id")
  valid_607907 = validateParameter(valid_607907, JString, required = true,
                                 default = nil)
  if valid_607907 != nil:
    section.add "restapi_id", valid_607907
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  section = newJObject()
  var valid_607908 = query.getOrDefault("limit")
  valid_607908 = validateParameter(valid_607908, JInt, required = false, default = nil)
  if valid_607908 != nil:
    section.add "limit", valid_607908
  var valid_607909 = query.getOrDefault("position")
  valid_607909 = validateParameter(valid_607909, JString, required = false,
                                 default = nil)
  if valid_607909 != nil:
    section.add "position", valid_607909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607910 = header.getOrDefault("X-Amz-Signature")
  valid_607910 = validateParameter(valid_607910, JString, required = false,
                                 default = nil)
  if valid_607910 != nil:
    section.add "X-Amz-Signature", valid_607910
  var valid_607911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607911 = validateParameter(valid_607911, JString, required = false,
                                 default = nil)
  if valid_607911 != nil:
    section.add "X-Amz-Content-Sha256", valid_607911
  var valid_607912 = header.getOrDefault("X-Amz-Date")
  valid_607912 = validateParameter(valid_607912, JString, required = false,
                                 default = nil)
  if valid_607912 != nil:
    section.add "X-Amz-Date", valid_607912
  var valid_607913 = header.getOrDefault("X-Amz-Credential")
  valid_607913 = validateParameter(valid_607913, JString, required = false,
                                 default = nil)
  if valid_607913 != nil:
    section.add "X-Amz-Credential", valid_607913
  var valid_607914 = header.getOrDefault("X-Amz-Security-Token")
  valid_607914 = validateParameter(valid_607914, JString, required = false,
                                 default = nil)
  if valid_607914 != nil:
    section.add "X-Amz-Security-Token", valid_607914
  var valid_607915 = header.getOrDefault("X-Amz-Algorithm")
  valid_607915 = validateParameter(valid_607915, JString, required = false,
                                 default = nil)
  if valid_607915 != nil:
    section.add "X-Amz-Algorithm", valid_607915
  var valid_607916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607916 = validateParameter(valid_607916, JString, required = false,
                                 default = nil)
  if valid_607916 != nil:
    section.add "X-Amz-SignedHeaders", valid_607916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607917: Call_GetGatewayResponses_607904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_607917.validator(path, query, header, formData, body)
  let scheme = call_607917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607917.url(scheme.get, call_607917.host, call_607917.base,
                         call_607917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607917, url, valid)

proc call*(call_607918: Call_GetGatewayResponses_607904; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_607919 = newJObject()
  var query_607920 = newJObject()
  add(query_607920, "limit", newJInt(limit))
  add(query_607920, "position", newJString(position))
  add(path_607919, "restapi_id", newJString(restapiId))
  result = call_607918.call(path_607919, query_607920, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_607904(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_607905, base: "/",
    url: url_GetGatewayResponses_607906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_607921 = ref object of OpenApiRestCall_605573
proc url_GetModelTemplate_607923(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_607922(path: JsonNode; query: JsonNode;
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
  var valid_607924 = path.getOrDefault("model_name")
  valid_607924 = validateParameter(valid_607924, JString, required = true,
                                 default = nil)
  if valid_607924 != nil:
    section.add "model_name", valid_607924
  var valid_607925 = path.getOrDefault("restapi_id")
  valid_607925 = validateParameter(valid_607925, JString, required = true,
                                 default = nil)
  if valid_607925 != nil:
    section.add "restapi_id", valid_607925
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607926 = header.getOrDefault("X-Amz-Signature")
  valid_607926 = validateParameter(valid_607926, JString, required = false,
                                 default = nil)
  if valid_607926 != nil:
    section.add "X-Amz-Signature", valid_607926
  var valid_607927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607927 = validateParameter(valid_607927, JString, required = false,
                                 default = nil)
  if valid_607927 != nil:
    section.add "X-Amz-Content-Sha256", valid_607927
  var valid_607928 = header.getOrDefault("X-Amz-Date")
  valid_607928 = validateParameter(valid_607928, JString, required = false,
                                 default = nil)
  if valid_607928 != nil:
    section.add "X-Amz-Date", valid_607928
  var valid_607929 = header.getOrDefault("X-Amz-Credential")
  valid_607929 = validateParameter(valid_607929, JString, required = false,
                                 default = nil)
  if valid_607929 != nil:
    section.add "X-Amz-Credential", valid_607929
  var valid_607930 = header.getOrDefault("X-Amz-Security-Token")
  valid_607930 = validateParameter(valid_607930, JString, required = false,
                                 default = nil)
  if valid_607930 != nil:
    section.add "X-Amz-Security-Token", valid_607930
  var valid_607931 = header.getOrDefault("X-Amz-Algorithm")
  valid_607931 = validateParameter(valid_607931, JString, required = false,
                                 default = nil)
  if valid_607931 != nil:
    section.add "X-Amz-Algorithm", valid_607931
  var valid_607932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607932 = validateParameter(valid_607932, JString, required = false,
                                 default = nil)
  if valid_607932 != nil:
    section.add "X-Amz-SignedHeaders", valid_607932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607933: Call_GetModelTemplate_607921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_607933.validator(path, query, header, formData, body)
  let scheme = call_607933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607933.url(scheme.get, call_607933.host, call_607933.base,
                         call_607933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607933, url, valid)

proc call*(call_607934: Call_GetModelTemplate_607921; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_607935 = newJObject()
  add(path_607935, "model_name", newJString(modelName))
  add(path_607935, "restapi_id", newJString(restapiId))
  result = call_607934.call(path_607935, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_607921(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_607922, base: "/",
    url: url_GetModelTemplate_607923, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_607936 = ref object of OpenApiRestCall_605573
proc url_GetResources_607938(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_607937(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607939 = path.getOrDefault("restapi_id")
  valid_607939 = validateParameter(valid_607939, JString, required = true,
                                 default = nil)
  if valid_607939 != nil:
    section.add "restapi_id", valid_607939
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  section = newJObject()
  var valid_607940 = query.getOrDefault("limit")
  valid_607940 = validateParameter(valid_607940, JInt, required = false, default = nil)
  if valid_607940 != nil:
    section.add "limit", valid_607940
  var valid_607941 = query.getOrDefault("position")
  valid_607941 = validateParameter(valid_607941, JString, required = false,
                                 default = nil)
  if valid_607941 != nil:
    section.add "position", valid_607941
  var valid_607942 = query.getOrDefault("embed")
  valid_607942 = validateParameter(valid_607942, JArray, required = false,
                                 default = nil)
  if valid_607942 != nil:
    section.add "embed", valid_607942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607943 = header.getOrDefault("X-Amz-Signature")
  valid_607943 = validateParameter(valid_607943, JString, required = false,
                                 default = nil)
  if valid_607943 != nil:
    section.add "X-Amz-Signature", valid_607943
  var valid_607944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607944 = validateParameter(valid_607944, JString, required = false,
                                 default = nil)
  if valid_607944 != nil:
    section.add "X-Amz-Content-Sha256", valid_607944
  var valid_607945 = header.getOrDefault("X-Amz-Date")
  valid_607945 = validateParameter(valid_607945, JString, required = false,
                                 default = nil)
  if valid_607945 != nil:
    section.add "X-Amz-Date", valid_607945
  var valid_607946 = header.getOrDefault("X-Amz-Credential")
  valid_607946 = validateParameter(valid_607946, JString, required = false,
                                 default = nil)
  if valid_607946 != nil:
    section.add "X-Amz-Credential", valid_607946
  var valid_607947 = header.getOrDefault("X-Amz-Security-Token")
  valid_607947 = validateParameter(valid_607947, JString, required = false,
                                 default = nil)
  if valid_607947 != nil:
    section.add "X-Amz-Security-Token", valid_607947
  var valid_607948 = header.getOrDefault("X-Amz-Algorithm")
  valid_607948 = validateParameter(valid_607948, JString, required = false,
                                 default = nil)
  if valid_607948 != nil:
    section.add "X-Amz-Algorithm", valid_607948
  var valid_607949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607949 = validateParameter(valid_607949, JString, required = false,
                                 default = nil)
  if valid_607949 != nil:
    section.add "X-Amz-SignedHeaders", valid_607949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607950: Call_GetResources_607936; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_607950.validator(path, query, header, formData, body)
  let scheme = call_607950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607950.url(scheme.get, call_607950.host, call_607950.base,
                         call_607950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607950, url, valid)

proc call*(call_607951: Call_GetResources_607936; restapiId: string; limit: int = 0;
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
  var path_607952 = newJObject()
  var query_607953 = newJObject()
  add(query_607953, "limit", newJInt(limit))
  add(query_607953, "position", newJString(position))
  add(path_607952, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_607953.add "embed", embed
  result = call_607951.call(path_607952, query_607953, nil, nil, nil)

var getResources* = Call_GetResources_607936(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_607937,
    base: "/", url: url_GetResources_607938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_607954 = ref object of OpenApiRestCall_605573
proc url_GetSdk_607956(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdk_607955(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607957 = path.getOrDefault("sdk_type")
  valid_607957 = validateParameter(valid_607957, JString, required = true,
                                 default = nil)
  if valid_607957 != nil:
    section.add "sdk_type", valid_607957
  var valid_607958 = path.getOrDefault("restapi_id")
  valid_607958 = validateParameter(valid_607958, JString, required = true,
                                 default = nil)
  if valid_607958 != nil:
    section.add "restapi_id", valid_607958
  var valid_607959 = path.getOrDefault("stage_name")
  valid_607959 = validateParameter(valid_607959, JString, required = true,
                                 default = nil)
  if valid_607959 != nil:
    section.add "stage_name", valid_607959
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_607960 = query.getOrDefault("parameters.2.value")
  valid_607960 = validateParameter(valid_607960, JString, required = false,
                                 default = nil)
  if valid_607960 != nil:
    section.add "parameters.2.value", valid_607960
  var valid_607961 = query.getOrDefault("parameters.1.value")
  valid_607961 = validateParameter(valid_607961, JString, required = false,
                                 default = nil)
  if valid_607961 != nil:
    section.add "parameters.1.value", valid_607961
  var valid_607962 = query.getOrDefault("parameters.1.key")
  valid_607962 = validateParameter(valid_607962, JString, required = false,
                                 default = nil)
  if valid_607962 != nil:
    section.add "parameters.1.key", valid_607962
  var valid_607963 = query.getOrDefault("parameters.2.key")
  valid_607963 = validateParameter(valid_607963, JString, required = false,
                                 default = nil)
  if valid_607963 != nil:
    section.add "parameters.2.key", valid_607963
  var valid_607964 = query.getOrDefault("parameters.0.value")
  valid_607964 = validateParameter(valid_607964, JString, required = false,
                                 default = nil)
  if valid_607964 != nil:
    section.add "parameters.0.value", valid_607964
  var valid_607965 = query.getOrDefault("parameters.0.key")
  valid_607965 = validateParameter(valid_607965, JString, required = false,
                                 default = nil)
  if valid_607965 != nil:
    section.add "parameters.0.key", valid_607965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607966 = header.getOrDefault("X-Amz-Signature")
  valid_607966 = validateParameter(valid_607966, JString, required = false,
                                 default = nil)
  if valid_607966 != nil:
    section.add "X-Amz-Signature", valid_607966
  var valid_607967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607967 = validateParameter(valid_607967, JString, required = false,
                                 default = nil)
  if valid_607967 != nil:
    section.add "X-Amz-Content-Sha256", valid_607967
  var valid_607968 = header.getOrDefault("X-Amz-Date")
  valid_607968 = validateParameter(valid_607968, JString, required = false,
                                 default = nil)
  if valid_607968 != nil:
    section.add "X-Amz-Date", valid_607968
  var valid_607969 = header.getOrDefault("X-Amz-Credential")
  valid_607969 = validateParameter(valid_607969, JString, required = false,
                                 default = nil)
  if valid_607969 != nil:
    section.add "X-Amz-Credential", valid_607969
  var valid_607970 = header.getOrDefault("X-Amz-Security-Token")
  valid_607970 = validateParameter(valid_607970, JString, required = false,
                                 default = nil)
  if valid_607970 != nil:
    section.add "X-Amz-Security-Token", valid_607970
  var valid_607971 = header.getOrDefault("X-Amz-Algorithm")
  valid_607971 = validateParameter(valid_607971, JString, required = false,
                                 default = nil)
  if valid_607971 != nil:
    section.add "X-Amz-Algorithm", valid_607971
  var valid_607972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607972 = validateParameter(valid_607972, JString, required = false,
                                 default = nil)
  if valid_607972 != nil:
    section.add "X-Amz-SignedHeaders", valid_607972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607973: Call_GetSdk_607954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_607973.validator(path, query, header, formData, body)
  let scheme = call_607973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607973.url(scheme.get, call_607973.host, call_607973.base,
                         call_607973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607973, url, valid)

proc call*(call_607974: Call_GetSdk_607954; sdkType: string; restapiId: string;
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
  var path_607975 = newJObject()
  var query_607976 = newJObject()
  add(path_607975, "sdk_type", newJString(sdkType))
  add(query_607976, "parameters.2.value", newJString(parameters2Value))
  add(query_607976, "parameters.1.value", newJString(parameters1Value))
  add(query_607976, "parameters.1.key", newJString(parameters1Key))
  add(path_607975, "restapi_id", newJString(restapiId))
  add(query_607976, "parameters.2.key", newJString(parameters2Key))
  add(path_607975, "stage_name", newJString(stageName))
  add(query_607976, "parameters.0.value", newJString(parameters0Value))
  add(query_607976, "parameters.0.key", newJString(parameters0Key))
  result = call_607974.call(path_607975, query_607976, nil, nil, nil)

var getSdk* = Call_GetSdk_607954(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_607955, base: "/",
                              url: url_GetSdk_607956,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_607977 = ref object of OpenApiRestCall_605573
proc url_GetSdkType_607979(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdkType_607978(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_607980 = path.getOrDefault("sdktype_id")
  valid_607980 = validateParameter(valid_607980, JString, required = true,
                                 default = nil)
  if valid_607980 != nil:
    section.add "sdktype_id", valid_607980
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607981 = header.getOrDefault("X-Amz-Signature")
  valid_607981 = validateParameter(valid_607981, JString, required = false,
                                 default = nil)
  if valid_607981 != nil:
    section.add "X-Amz-Signature", valid_607981
  var valid_607982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607982 = validateParameter(valid_607982, JString, required = false,
                                 default = nil)
  if valid_607982 != nil:
    section.add "X-Amz-Content-Sha256", valid_607982
  var valid_607983 = header.getOrDefault("X-Amz-Date")
  valid_607983 = validateParameter(valid_607983, JString, required = false,
                                 default = nil)
  if valid_607983 != nil:
    section.add "X-Amz-Date", valid_607983
  var valid_607984 = header.getOrDefault("X-Amz-Credential")
  valid_607984 = validateParameter(valid_607984, JString, required = false,
                                 default = nil)
  if valid_607984 != nil:
    section.add "X-Amz-Credential", valid_607984
  var valid_607985 = header.getOrDefault("X-Amz-Security-Token")
  valid_607985 = validateParameter(valid_607985, JString, required = false,
                                 default = nil)
  if valid_607985 != nil:
    section.add "X-Amz-Security-Token", valid_607985
  var valid_607986 = header.getOrDefault("X-Amz-Algorithm")
  valid_607986 = validateParameter(valid_607986, JString, required = false,
                                 default = nil)
  if valid_607986 != nil:
    section.add "X-Amz-Algorithm", valid_607986
  var valid_607987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607987 = validateParameter(valid_607987, JString, required = false,
                                 default = nil)
  if valid_607987 != nil:
    section.add "X-Amz-SignedHeaders", valid_607987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607988: Call_GetSdkType_607977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607988.validator(path, query, header, formData, body)
  let scheme = call_607988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607988.url(scheme.get, call_607988.host, call_607988.base,
                         call_607988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607988, url, valid)

proc call*(call_607989: Call_GetSdkType_607977; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_607990 = newJObject()
  add(path_607990, "sdktype_id", newJString(sdktypeId))
  result = call_607989.call(path_607990, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_607977(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_607978,
                                      base: "/", url: url_GetSdkType_607979,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_607991 = ref object of OpenApiRestCall_605573
proc url_GetSdkTypes_607993(protocol: Scheme; host: string; base: string;
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

proc validate_GetSdkTypes_607992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607994 = query.getOrDefault("limit")
  valid_607994 = validateParameter(valid_607994, JInt, required = false, default = nil)
  if valid_607994 != nil:
    section.add "limit", valid_607994
  var valid_607995 = query.getOrDefault("position")
  valid_607995 = validateParameter(valid_607995, JString, required = false,
                                 default = nil)
  if valid_607995 != nil:
    section.add "position", valid_607995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607996 = header.getOrDefault("X-Amz-Signature")
  valid_607996 = validateParameter(valid_607996, JString, required = false,
                                 default = nil)
  if valid_607996 != nil:
    section.add "X-Amz-Signature", valid_607996
  var valid_607997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607997 = validateParameter(valid_607997, JString, required = false,
                                 default = nil)
  if valid_607997 != nil:
    section.add "X-Amz-Content-Sha256", valid_607997
  var valid_607998 = header.getOrDefault("X-Amz-Date")
  valid_607998 = validateParameter(valid_607998, JString, required = false,
                                 default = nil)
  if valid_607998 != nil:
    section.add "X-Amz-Date", valid_607998
  var valid_607999 = header.getOrDefault("X-Amz-Credential")
  valid_607999 = validateParameter(valid_607999, JString, required = false,
                                 default = nil)
  if valid_607999 != nil:
    section.add "X-Amz-Credential", valid_607999
  var valid_608000 = header.getOrDefault("X-Amz-Security-Token")
  valid_608000 = validateParameter(valid_608000, JString, required = false,
                                 default = nil)
  if valid_608000 != nil:
    section.add "X-Amz-Security-Token", valid_608000
  var valid_608001 = header.getOrDefault("X-Amz-Algorithm")
  valid_608001 = validateParameter(valid_608001, JString, required = false,
                                 default = nil)
  if valid_608001 != nil:
    section.add "X-Amz-Algorithm", valid_608001
  var valid_608002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608002 = validateParameter(valid_608002, JString, required = false,
                                 default = nil)
  if valid_608002 != nil:
    section.add "X-Amz-SignedHeaders", valid_608002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608003: Call_GetSdkTypes_607991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608003.validator(path, query, header, formData, body)
  let scheme = call_608003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608003.url(scheme.get, call_608003.host, call_608003.base,
                         call_608003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608003, url, valid)

proc call*(call_608004: Call_GetSdkTypes_607991; limit: int = 0; position: string = ""): Recallable =
  ## getSdkTypes
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_608005 = newJObject()
  add(query_608005, "limit", newJInt(limit))
  add(query_608005, "position", newJString(position))
  result = call_608004.call(nil, query_608005, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_607991(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_607992,
                                        base: "/", url: url_GetSdkTypes_607993,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_608023 = ref object of OpenApiRestCall_605573
proc url_TagResource_608025(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_608024(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608026 = path.getOrDefault("resource_arn")
  valid_608026 = validateParameter(valid_608026, JString, required = true,
                                 default = nil)
  if valid_608026 != nil:
    section.add "resource_arn", valid_608026
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608027 = header.getOrDefault("X-Amz-Signature")
  valid_608027 = validateParameter(valid_608027, JString, required = false,
                                 default = nil)
  if valid_608027 != nil:
    section.add "X-Amz-Signature", valid_608027
  var valid_608028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608028 = validateParameter(valid_608028, JString, required = false,
                                 default = nil)
  if valid_608028 != nil:
    section.add "X-Amz-Content-Sha256", valid_608028
  var valid_608029 = header.getOrDefault("X-Amz-Date")
  valid_608029 = validateParameter(valid_608029, JString, required = false,
                                 default = nil)
  if valid_608029 != nil:
    section.add "X-Amz-Date", valid_608029
  var valid_608030 = header.getOrDefault("X-Amz-Credential")
  valid_608030 = validateParameter(valid_608030, JString, required = false,
                                 default = nil)
  if valid_608030 != nil:
    section.add "X-Amz-Credential", valid_608030
  var valid_608031 = header.getOrDefault("X-Amz-Security-Token")
  valid_608031 = validateParameter(valid_608031, JString, required = false,
                                 default = nil)
  if valid_608031 != nil:
    section.add "X-Amz-Security-Token", valid_608031
  var valid_608032 = header.getOrDefault("X-Amz-Algorithm")
  valid_608032 = validateParameter(valid_608032, JString, required = false,
                                 default = nil)
  if valid_608032 != nil:
    section.add "X-Amz-Algorithm", valid_608032
  var valid_608033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608033 = validateParameter(valid_608033, JString, required = false,
                                 default = nil)
  if valid_608033 != nil:
    section.add "X-Amz-SignedHeaders", valid_608033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608035: Call_TagResource_608023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_608035.validator(path, query, header, formData, body)
  let scheme = call_608035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608035.url(scheme.get, call_608035.host, call_608035.base,
                         call_608035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608035, url, valid)

proc call*(call_608036: Call_TagResource_608023; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_608037 = newJObject()
  var body_608038 = newJObject()
  add(path_608037, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_608038 = body
  result = call_608036.call(path_608037, nil, nil, nil, body_608038)

var tagResource* = Call_TagResource_608023(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_608024,
                                        base: "/", url: url_TagResource_608025,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_608006 = ref object of OpenApiRestCall_605573
proc url_GetTags_608008(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_608007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608009 = path.getOrDefault("resource_arn")
  valid_608009 = validateParameter(valid_608009, JString, required = true,
                                 default = nil)
  if valid_608009 != nil:
    section.add "resource_arn", valid_608009
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  section = newJObject()
  var valid_608010 = query.getOrDefault("limit")
  valid_608010 = validateParameter(valid_608010, JInt, required = false, default = nil)
  if valid_608010 != nil:
    section.add "limit", valid_608010
  var valid_608011 = query.getOrDefault("position")
  valid_608011 = validateParameter(valid_608011, JString, required = false,
                                 default = nil)
  if valid_608011 != nil:
    section.add "position", valid_608011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608012 = header.getOrDefault("X-Amz-Signature")
  valid_608012 = validateParameter(valid_608012, JString, required = false,
                                 default = nil)
  if valid_608012 != nil:
    section.add "X-Amz-Signature", valid_608012
  var valid_608013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608013 = validateParameter(valid_608013, JString, required = false,
                                 default = nil)
  if valid_608013 != nil:
    section.add "X-Amz-Content-Sha256", valid_608013
  var valid_608014 = header.getOrDefault("X-Amz-Date")
  valid_608014 = validateParameter(valid_608014, JString, required = false,
                                 default = nil)
  if valid_608014 != nil:
    section.add "X-Amz-Date", valid_608014
  var valid_608015 = header.getOrDefault("X-Amz-Credential")
  valid_608015 = validateParameter(valid_608015, JString, required = false,
                                 default = nil)
  if valid_608015 != nil:
    section.add "X-Amz-Credential", valid_608015
  var valid_608016 = header.getOrDefault("X-Amz-Security-Token")
  valid_608016 = validateParameter(valid_608016, JString, required = false,
                                 default = nil)
  if valid_608016 != nil:
    section.add "X-Amz-Security-Token", valid_608016
  var valid_608017 = header.getOrDefault("X-Amz-Algorithm")
  valid_608017 = validateParameter(valid_608017, JString, required = false,
                                 default = nil)
  if valid_608017 != nil:
    section.add "X-Amz-Algorithm", valid_608017
  var valid_608018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608018 = validateParameter(valid_608018, JString, required = false,
                                 default = nil)
  if valid_608018 != nil:
    section.add "X-Amz-SignedHeaders", valid_608018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608019: Call_GetTags_608006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_608019.validator(path, query, header, formData, body)
  let scheme = call_608019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608019.url(scheme.get, call_608019.host, call_608019.base,
                         call_608019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608019, url, valid)

proc call*(call_608020: Call_GetTags_608006; resourceArn: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  var path_608021 = newJObject()
  var query_608022 = newJObject()
  add(query_608022, "limit", newJInt(limit))
  add(path_608021, "resource_arn", newJString(resourceArn))
  add(query_608022, "position", newJString(position))
  result = call_608020.call(path_608021, query_608022, nil, nil, nil)

var getTags* = Call_GetTags_608006(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_608007, base: "/",
                                url: url_GetTags_608008,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_608039 = ref object of OpenApiRestCall_605573
proc url_GetUsage_608041(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUsage_608040(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608042 = path.getOrDefault("usageplanId")
  valid_608042 = validateParameter(valid_608042, JString, required = true,
                                 default = nil)
  if valid_608042 != nil:
    section.add "usageplanId", valid_608042
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
  var valid_608043 = query.getOrDefault("limit")
  valid_608043 = validateParameter(valid_608043, JInt, required = false, default = nil)
  if valid_608043 != nil:
    section.add "limit", valid_608043
  assert query != nil, "query argument is necessary due to required `endDate` field"
  var valid_608044 = query.getOrDefault("endDate")
  valid_608044 = validateParameter(valid_608044, JString, required = true,
                                 default = nil)
  if valid_608044 != nil:
    section.add "endDate", valid_608044
  var valid_608045 = query.getOrDefault("position")
  valid_608045 = validateParameter(valid_608045, JString, required = false,
                                 default = nil)
  if valid_608045 != nil:
    section.add "position", valid_608045
  var valid_608046 = query.getOrDefault("keyId")
  valid_608046 = validateParameter(valid_608046, JString, required = false,
                                 default = nil)
  if valid_608046 != nil:
    section.add "keyId", valid_608046
  var valid_608047 = query.getOrDefault("startDate")
  valid_608047 = validateParameter(valid_608047, JString, required = true,
                                 default = nil)
  if valid_608047 != nil:
    section.add "startDate", valid_608047
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608048 = header.getOrDefault("X-Amz-Signature")
  valid_608048 = validateParameter(valid_608048, JString, required = false,
                                 default = nil)
  if valid_608048 != nil:
    section.add "X-Amz-Signature", valid_608048
  var valid_608049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608049 = validateParameter(valid_608049, JString, required = false,
                                 default = nil)
  if valid_608049 != nil:
    section.add "X-Amz-Content-Sha256", valid_608049
  var valid_608050 = header.getOrDefault("X-Amz-Date")
  valid_608050 = validateParameter(valid_608050, JString, required = false,
                                 default = nil)
  if valid_608050 != nil:
    section.add "X-Amz-Date", valid_608050
  var valid_608051 = header.getOrDefault("X-Amz-Credential")
  valid_608051 = validateParameter(valid_608051, JString, required = false,
                                 default = nil)
  if valid_608051 != nil:
    section.add "X-Amz-Credential", valid_608051
  var valid_608052 = header.getOrDefault("X-Amz-Security-Token")
  valid_608052 = validateParameter(valid_608052, JString, required = false,
                                 default = nil)
  if valid_608052 != nil:
    section.add "X-Amz-Security-Token", valid_608052
  var valid_608053 = header.getOrDefault("X-Amz-Algorithm")
  valid_608053 = validateParameter(valid_608053, JString, required = false,
                                 default = nil)
  if valid_608053 != nil:
    section.add "X-Amz-Algorithm", valid_608053
  var valid_608054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608054 = validateParameter(valid_608054, JString, required = false,
                                 default = nil)
  if valid_608054 != nil:
    section.add "X-Amz-SignedHeaders", valid_608054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608055: Call_GetUsage_608039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_608055.validator(path, query, header, formData, body)
  let scheme = call_608055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608055.url(scheme.get, call_608055.host, call_608055.base,
                         call_608055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608055, url, valid)

proc call*(call_608056: Call_GetUsage_608039; usageplanId: string; endDate: string;
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
  var path_608057 = newJObject()
  var query_608058 = newJObject()
  add(path_608057, "usageplanId", newJString(usageplanId))
  add(query_608058, "limit", newJInt(limit))
  add(query_608058, "endDate", newJString(endDate))
  add(query_608058, "position", newJString(position))
  add(query_608058, "keyId", newJString(keyId))
  add(query_608058, "startDate", newJString(startDate))
  result = call_608056.call(path_608057, query_608058, nil, nil, nil)

var getUsage* = Call_GetUsage_608039(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_608040, base: "/",
                                  url: url_GetUsage_608041,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_608059 = ref object of OpenApiRestCall_605573
proc url_ImportApiKeys_608061(protocol: Scheme; host: string; base: string;
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

proc validate_ImportApiKeys_608060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608062 = query.getOrDefault("failonwarnings")
  valid_608062 = validateParameter(valid_608062, JBool, required = false, default = nil)
  if valid_608062 != nil:
    section.add "failonwarnings", valid_608062
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_608063 = query.getOrDefault("mode")
  valid_608063 = validateParameter(valid_608063, JString, required = true,
                                 default = newJString("import"))
  if valid_608063 != nil:
    section.add "mode", valid_608063
  var valid_608064 = query.getOrDefault("format")
  valid_608064 = validateParameter(valid_608064, JString, required = true,
                                 default = newJString("csv"))
  if valid_608064 != nil:
    section.add "format", valid_608064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608065 = header.getOrDefault("X-Amz-Signature")
  valid_608065 = validateParameter(valid_608065, JString, required = false,
                                 default = nil)
  if valid_608065 != nil:
    section.add "X-Amz-Signature", valid_608065
  var valid_608066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608066 = validateParameter(valid_608066, JString, required = false,
                                 default = nil)
  if valid_608066 != nil:
    section.add "X-Amz-Content-Sha256", valid_608066
  var valid_608067 = header.getOrDefault("X-Amz-Date")
  valid_608067 = validateParameter(valid_608067, JString, required = false,
                                 default = nil)
  if valid_608067 != nil:
    section.add "X-Amz-Date", valid_608067
  var valid_608068 = header.getOrDefault("X-Amz-Credential")
  valid_608068 = validateParameter(valid_608068, JString, required = false,
                                 default = nil)
  if valid_608068 != nil:
    section.add "X-Amz-Credential", valid_608068
  var valid_608069 = header.getOrDefault("X-Amz-Security-Token")
  valid_608069 = validateParameter(valid_608069, JString, required = false,
                                 default = nil)
  if valid_608069 != nil:
    section.add "X-Amz-Security-Token", valid_608069
  var valid_608070 = header.getOrDefault("X-Amz-Algorithm")
  valid_608070 = validateParameter(valid_608070, JString, required = false,
                                 default = nil)
  if valid_608070 != nil:
    section.add "X-Amz-Algorithm", valid_608070
  var valid_608071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608071 = validateParameter(valid_608071, JString, required = false,
                                 default = nil)
  if valid_608071 != nil:
    section.add "X-Amz-SignedHeaders", valid_608071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608073: Call_ImportApiKeys_608059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_608073.validator(path, query, header, formData, body)
  let scheme = call_608073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608073.url(scheme.get, call_608073.host, call_608073.base,
                         call_608073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608073, url, valid)

proc call*(call_608074: Call_ImportApiKeys_608059; body: JsonNode;
          failonwarnings: bool = false; mode: string = "import"; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   mode: string (required)
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_608075 = newJObject()
  var body_608076 = newJObject()
  add(query_608075, "failonwarnings", newJBool(failonwarnings))
  add(query_608075, "mode", newJString(mode))
  if body != nil:
    body_608076 = body
  add(query_608075, "format", newJString(format))
  result = call_608074.call(nil, query_608075, nil, nil, body_608076)

var importApiKeys* = Call_ImportApiKeys_608059(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_608060,
    base: "/", url: url_ImportApiKeys_608061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_608077 = ref object of OpenApiRestCall_605573
proc url_ImportRestApi_608079(protocol: Scheme; host: string; base: string;
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

proc validate_ImportRestApi_608078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608080 = query.getOrDefault("failonwarnings")
  valid_608080 = validateParameter(valid_608080, JBool, required = false, default = nil)
  if valid_608080 != nil:
    section.add "failonwarnings", valid_608080
  var valid_608081 = query.getOrDefault("parameters.2.value")
  valid_608081 = validateParameter(valid_608081, JString, required = false,
                                 default = nil)
  if valid_608081 != nil:
    section.add "parameters.2.value", valid_608081
  var valid_608082 = query.getOrDefault("parameters.1.value")
  valid_608082 = validateParameter(valid_608082, JString, required = false,
                                 default = nil)
  if valid_608082 != nil:
    section.add "parameters.1.value", valid_608082
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_608083 = query.getOrDefault("mode")
  valid_608083 = validateParameter(valid_608083, JString, required = true,
                                 default = newJString("import"))
  if valid_608083 != nil:
    section.add "mode", valid_608083
  var valid_608084 = query.getOrDefault("parameters.1.key")
  valid_608084 = validateParameter(valid_608084, JString, required = false,
                                 default = nil)
  if valid_608084 != nil:
    section.add "parameters.1.key", valid_608084
  var valid_608085 = query.getOrDefault("parameters.2.key")
  valid_608085 = validateParameter(valid_608085, JString, required = false,
                                 default = nil)
  if valid_608085 != nil:
    section.add "parameters.2.key", valid_608085
  var valid_608086 = query.getOrDefault("parameters.0.value")
  valid_608086 = validateParameter(valid_608086, JString, required = false,
                                 default = nil)
  if valid_608086 != nil:
    section.add "parameters.0.value", valid_608086
  var valid_608087 = query.getOrDefault("parameters.0.key")
  valid_608087 = validateParameter(valid_608087, JString, required = false,
                                 default = nil)
  if valid_608087 != nil:
    section.add "parameters.0.key", valid_608087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608088 = header.getOrDefault("X-Amz-Signature")
  valid_608088 = validateParameter(valid_608088, JString, required = false,
                                 default = nil)
  if valid_608088 != nil:
    section.add "X-Amz-Signature", valid_608088
  var valid_608089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608089 = validateParameter(valid_608089, JString, required = false,
                                 default = nil)
  if valid_608089 != nil:
    section.add "X-Amz-Content-Sha256", valid_608089
  var valid_608090 = header.getOrDefault("X-Amz-Date")
  valid_608090 = validateParameter(valid_608090, JString, required = false,
                                 default = nil)
  if valid_608090 != nil:
    section.add "X-Amz-Date", valid_608090
  var valid_608091 = header.getOrDefault("X-Amz-Credential")
  valid_608091 = validateParameter(valid_608091, JString, required = false,
                                 default = nil)
  if valid_608091 != nil:
    section.add "X-Amz-Credential", valid_608091
  var valid_608092 = header.getOrDefault("X-Amz-Security-Token")
  valid_608092 = validateParameter(valid_608092, JString, required = false,
                                 default = nil)
  if valid_608092 != nil:
    section.add "X-Amz-Security-Token", valid_608092
  var valid_608093 = header.getOrDefault("X-Amz-Algorithm")
  valid_608093 = validateParameter(valid_608093, JString, required = false,
                                 default = nil)
  if valid_608093 != nil:
    section.add "X-Amz-Algorithm", valid_608093
  var valid_608094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608094 = validateParameter(valid_608094, JString, required = false,
                                 default = nil)
  if valid_608094 != nil:
    section.add "X-Amz-SignedHeaders", valid_608094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608096: Call_ImportRestApi_608077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_608096.validator(path, query, header, formData, body)
  let scheme = call_608096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608096.url(scheme.get, call_608096.host, call_608096.base,
                         call_608096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608096, url, valid)

proc call*(call_608097: Call_ImportRestApi_608077; body: JsonNode;
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
  var query_608098 = newJObject()
  var body_608099 = newJObject()
  add(query_608098, "failonwarnings", newJBool(failonwarnings))
  add(query_608098, "parameters.2.value", newJString(parameters2Value))
  add(query_608098, "parameters.1.value", newJString(parameters1Value))
  add(query_608098, "mode", newJString(mode))
  add(query_608098, "parameters.1.key", newJString(parameters1Key))
  add(query_608098, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_608099 = body
  add(query_608098, "parameters.0.value", newJString(parameters0Value))
  add(query_608098, "parameters.0.key", newJString(parameters0Key))
  result = call_608097.call(nil, query_608098, nil, nil, body_608099)

var importRestApi* = Call_ImportRestApi_608077(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_608078,
    base: "/", url: url_ImportRestApi_608079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_608100 = ref object of OpenApiRestCall_605573
proc url_UntagResource_608102(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_608101(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608103 = path.getOrDefault("resource_arn")
  valid_608103 = validateParameter(valid_608103, JString, required = true,
                                 default = nil)
  if valid_608103 != nil:
    section.add "resource_arn", valid_608103
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_608104 = query.getOrDefault("tagKeys")
  valid_608104 = validateParameter(valid_608104, JArray, required = true, default = nil)
  if valid_608104 != nil:
    section.add "tagKeys", valid_608104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608105 = header.getOrDefault("X-Amz-Signature")
  valid_608105 = validateParameter(valid_608105, JString, required = false,
                                 default = nil)
  if valid_608105 != nil:
    section.add "X-Amz-Signature", valid_608105
  var valid_608106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608106 = validateParameter(valid_608106, JString, required = false,
                                 default = nil)
  if valid_608106 != nil:
    section.add "X-Amz-Content-Sha256", valid_608106
  var valid_608107 = header.getOrDefault("X-Amz-Date")
  valid_608107 = validateParameter(valid_608107, JString, required = false,
                                 default = nil)
  if valid_608107 != nil:
    section.add "X-Amz-Date", valid_608107
  var valid_608108 = header.getOrDefault("X-Amz-Credential")
  valid_608108 = validateParameter(valid_608108, JString, required = false,
                                 default = nil)
  if valid_608108 != nil:
    section.add "X-Amz-Credential", valid_608108
  var valid_608109 = header.getOrDefault("X-Amz-Security-Token")
  valid_608109 = validateParameter(valid_608109, JString, required = false,
                                 default = nil)
  if valid_608109 != nil:
    section.add "X-Amz-Security-Token", valid_608109
  var valid_608110 = header.getOrDefault("X-Amz-Algorithm")
  valid_608110 = validateParameter(valid_608110, JString, required = false,
                                 default = nil)
  if valid_608110 != nil:
    section.add "X-Amz-Algorithm", valid_608110
  var valid_608111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608111 = validateParameter(valid_608111, JString, required = false,
                                 default = nil)
  if valid_608111 != nil:
    section.add "X-Amz-SignedHeaders", valid_608111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608112: Call_UntagResource_608100; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_608112.validator(path, query, header, formData, body)
  let scheme = call_608112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608112.url(scheme.get, call_608112.host, call_608112.base,
                         call_608112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608112, url, valid)

proc call*(call_608113: Call_UntagResource_608100; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_608114 = newJObject()
  var query_608115 = newJObject()
  add(path_608114, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_608115.add "tagKeys", tagKeys
  result = call_608113.call(path_608114, query_608115, nil, nil, nil)

var untagResource* = Call_UntagResource_608100(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_608101,
    base: "/", url: url_UntagResource_608102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_608116 = ref object of OpenApiRestCall_605573
proc url_UpdateUsage_608118(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsage_608117(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608119 = path.getOrDefault("usageplanId")
  valid_608119 = validateParameter(valid_608119, JString, required = true,
                                 default = nil)
  if valid_608119 != nil:
    section.add "usageplanId", valid_608119
  var valid_608120 = path.getOrDefault("keyId")
  valid_608120 = validateParameter(valid_608120, JString, required = true,
                                 default = nil)
  if valid_608120 != nil:
    section.add "keyId", valid_608120
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608121 = header.getOrDefault("X-Amz-Signature")
  valid_608121 = validateParameter(valid_608121, JString, required = false,
                                 default = nil)
  if valid_608121 != nil:
    section.add "X-Amz-Signature", valid_608121
  var valid_608122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608122 = validateParameter(valid_608122, JString, required = false,
                                 default = nil)
  if valid_608122 != nil:
    section.add "X-Amz-Content-Sha256", valid_608122
  var valid_608123 = header.getOrDefault("X-Amz-Date")
  valid_608123 = validateParameter(valid_608123, JString, required = false,
                                 default = nil)
  if valid_608123 != nil:
    section.add "X-Amz-Date", valid_608123
  var valid_608124 = header.getOrDefault("X-Amz-Credential")
  valid_608124 = validateParameter(valid_608124, JString, required = false,
                                 default = nil)
  if valid_608124 != nil:
    section.add "X-Amz-Credential", valid_608124
  var valid_608125 = header.getOrDefault("X-Amz-Security-Token")
  valid_608125 = validateParameter(valid_608125, JString, required = false,
                                 default = nil)
  if valid_608125 != nil:
    section.add "X-Amz-Security-Token", valid_608125
  var valid_608126 = header.getOrDefault("X-Amz-Algorithm")
  valid_608126 = validateParameter(valid_608126, JString, required = false,
                                 default = nil)
  if valid_608126 != nil:
    section.add "X-Amz-Algorithm", valid_608126
  var valid_608127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608127 = validateParameter(valid_608127, JString, required = false,
                                 default = nil)
  if valid_608127 != nil:
    section.add "X-Amz-SignedHeaders", valid_608127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608129: Call_UpdateUsage_608116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_608129.validator(path, query, header, formData, body)
  let scheme = call_608129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608129.url(scheme.get, call_608129.host, call_608129.base,
                         call_608129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608129, url, valid)

proc call*(call_608130: Call_UpdateUsage_608116; usageplanId: string; keyId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   body: JObject (required)
  var path_608131 = newJObject()
  var body_608132 = newJObject()
  add(path_608131, "usageplanId", newJString(usageplanId))
  add(path_608131, "keyId", newJString(keyId))
  if body != nil:
    body_608132 = body
  result = call_608130.call(path_608131, nil, nil, nil, body_608132)

var updateUsage* = Call_UpdateUsage_608116(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_608117,
                                        base: "/", url: url_UpdateUsage_608118,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
