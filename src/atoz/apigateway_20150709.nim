
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

  OpenApiRestCall_601373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601373): Option[Scheme] {.used.} =
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
  Call_CreateApiKey_601971 = ref object of OpenApiRestCall_601373
proc url_CreateApiKey_601973(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiKey_601972(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601974 = header.getOrDefault("X-Amz-Signature")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-Signature", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Content-Sha256", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Date")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Date", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-Credential")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Credential", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Security-Token")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Security-Token", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Algorithm")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Algorithm", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-SignedHeaders", valid_601980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601982: Call_CreateApiKey_601971; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_601982.validator(path, query, header, formData, body)
  let scheme = call_601982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601982.url(scheme.get, call_601982.host, call_601982.base,
                         call_601982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601982, url, valid)

proc call*(call_601983: Call_CreateApiKey_601971; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_601984 = newJObject()
  if body != nil:
    body_601984 = body
  result = call_601983.call(nil, nil, nil, nil, body_601984)

var createApiKey* = Call_CreateApiKey_601971(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_601972, base: "/", url: url_CreateApiKey_601973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_601711 = ref object of OpenApiRestCall_601373
proc url_GetApiKeys_601713(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKeys_601712(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601825 = query.getOrDefault("name")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "name", valid_601825
  var valid_601826 = query.getOrDefault("limit")
  valid_601826 = validateParameter(valid_601826, JInt, required = false, default = nil)
  if valid_601826 != nil:
    section.add "limit", valid_601826
  var valid_601827 = query.getOrDefault("position")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "position", valid_601827
  var valid_601828 = query.getOrDefault("includeValues")
  valid_601828 = validateParameter(valid_601828, JBool, required = false, default = nil)
  if valid_601828 != nil:
    section.add "includeValues", valid_601828
  var valid_601829 = query.getOrDefault("customerId")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "customerId", valid_601829
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601830 = header.getOrDefault("X-Amz-Signature")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Signature", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Content-Sha256", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-Date")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Date", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Credential")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Credential", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Security-Token")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Security-Token", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Algorithm")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Algorithm", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-SignedHeaders", valid_601836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601859: Call_GetApiKeys_601711; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_601859.validator(path, query, header, formData, body)
  let scheme = call_601859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601859.url(scheme.get, call_601859.host, call_601859.base,
                         call_601859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601859, url, valid)

proc call*(call_601930: Call_GetApiKeys_601711; name: string = ""; limit: int = 0;
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
  var query_601931 = newJObject()
  add(query_601931, "name", newJString(name))
  add(query_601931, "limit", newJInt(limit))
  add(query_601931, "position", newJString(position))
  add(query_601931, "includeValues", newJBool(includeValues))
  add(query_601931, "customerId", newJString(customerId))
  result = call_601930.call(nil, query_601931, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_601711(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_601712,
                                      base: "/", url: url_GetApiKeys_601713,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_602016 = ref object of OpenApiRestCall_601373
proc url_CreateAuthorizer_602018(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_602017(path: JsonNode; query: JsonNode;
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
  var valid_602019 = path.getOrDefault("restapi_id")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = nil)
  if valid_602019 != nil:
    section.add "restapi_id", valid_602019
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602020 = header.getOrDefault("X-Amz-Signature")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Signature", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Content-Sha256", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Date")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Date", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Credential")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Credential", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Security-Token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Security-Token", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Algorithm")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Algorithm", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-SignedHeaders", valid_602026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602028: Call_CreateAuthorizer_602016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_602028.validator(path, query, header, formData, body)
  let scheme = call_602028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602028.url(scheme.get, call_602028.host, call_602028.base,
                         call_602028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602028, url, valid)

proc call*(call_602029: Call_CreateAuthorizer_602016; restapiId: string;
          body: JsonNode): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602030 = newJObject()
  var body_602031 = newJObject()
  add(path_602030, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602031 = body
  result = call_602029.call(path_602030, nil, nil, nil, body_602031)

var createAuthorizer* = Call_CreateAuthorizer_602016(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_602017, base: "/",
    url: url_CreateAuthorizer_602018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_601985 = ref object of OpenApiRestCall_601373
proc url_GetAuthorizers_601987(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_601986(path: JsonNode; query: JsonNode;
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
  var valid_602002 = path.getOrDefault("restapi_id")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = nil)
  if valid_602002 != nil:
    section.add "restapi_id", valid_602002
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_602003 = query.getOrDefault("limit")
  valid_602003 = validateParameter(valid_602003, JInt, required = false, default = nil)
  if valid_602003 != nil:
    section.add "limit", valid_602003
  var valid_602004 = query.getOrDefault("position")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "position", valid_602004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602005 = header.getOrDefault("X-Amz-Signature")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Signature", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Content-Sha256", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Date")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Date", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Credential")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Credential", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Security-Token")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Security-Token", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Algorithm")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Algorithm", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-SignedHeaders", valid_602011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602012: Call_GetAuthorizers_601985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_602012.validator(path, query, header, formData, body)
  let scheme = call_602012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602012.url(scheme.get, call_602012.host, call_602012.base,
                         call_602012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602012, url, valid)

proc call*(call_602013: Call_GetAuthorizers_601985; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602014 = newJObject()
  var query_602015 = newJObject()
  add(query_602015, "limit", newJInt(limit))
  add(query_602015, "position", newJString(position))
  add(path_602014, "restapi_id", newJString(restapiId))
  result = call_602013.call(path_602014, query_602015, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_601985(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_601986, base: "/", url: url_GetAuthorizers_601987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_602049 = ref object of OpenApiRestCall_601373
proc url_CreateBasePathMapping_602051(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBasePathMapping_602050(path: JsonNode; query: JsonNode;
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
  var valid_602052 = path.getOrDefault("domain_name")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = nil)
  if valid_602052 != nil:
    section.add "domain_name", valid_602052
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602053 = header.getOrDefault("X-Amz-Signature")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Signature", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Content-Sha256", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Date")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Date", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Credential")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Credential", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Security-Token")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Security-Token", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Algorithm")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Algorithm", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-SignedHeaders", valid_602059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602061: Call_CreateBasePathMapping_602049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_602061.validator(path, query, header, formData, body)
  let scheme = call_602061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602061.url(scheme.get, call_602061.host, call_602061.base,
                         call_602061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602061, url, valid)

proc call*(call_602062: Call_CreateBasePathMapping_602049; body: JsonNode;
          domainName: string): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  var path_602063 = newJObject()
  var body_602064 = newJObject()
  if body != nil:
    body_602064 = body
  add(path_602063, "domain_name", newJString(domainName))
  result = call_602062.call(path_602063, nil, nil, nil, body_602064)

var createBasePathMapping* = Call_CreateBasePathMapping_602049(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_602050, base: "/",
    url: url_CreateBasePathMapping_602051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_602032 = ref object of OpenApiRestCall_601373
proc url_GetBasePathMappings_602034(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMappings_602033(path: JsonNode; query: JsonNode;
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
  var valid_602035 = path.getOrDefault("domain_name")
  valid_602035 = validateParameter(valid_602035, JString, required = true,
                                 default = nil)
  if valid_602035 != nil:
    section.add "domain_name", valid_602035
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_602036 = query.getOrDefault("limit")
  valid_602036 = validateParameter(valid_602036, JInt, required = false, default = nil)
  if valid_602036 != nil:
    section.add "limit", valid_602036
  var valid_602037 = query.getOrDefault("position")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "position", valid_602037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602038 = header.getOrDefault("X-Amz-Signature")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Signature", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Content-Sha256", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Date")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Date", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Credential")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Credential", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Security-Token")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Security-Token", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Algorithm")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Algorithm", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-SignedHeaders", valid_602044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602045: Call_GetBasePathMappings_602032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_602045.validator(path, query, header, formData, body)
  let scheme = call_602045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602045.url(scheme.get, call_602045.host, call_602045.base,
                         call_602045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602045, url, valid)

proc call*(call_602046: Call_GetBasePathMappings_602032; domainName: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  var path_602047 = newJObject()
  var query_602048 = newJObject()
  add(query_602048, "limit", newJInt(limit))
  add(query_602048, "position", newJString(position))
  add(path_602047, "domain_name", newJString(domainName))
  result = call_602046.call(path_602047, query_602048, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_602032(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_602033, base: "/",
    url: url_GetBasePathMappings_602034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_602082 = ref object of OpenApiRestCall_601373
proc url_CreateDeployment_602084(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_602083(path: JsonNode; query: JsonNode;
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
  var valid_602085 = path.getOrDefault("restapi_id")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = nil)
  if valid_602085 != nil:
    section.add "restapi_id", valid_602085
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602086 = header.getOrDefault("X-Amz-Signature")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Signature", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Content-Sha256", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Date")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Date", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Credential")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Credential", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Security-Token")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Security-Token", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Algorithm")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Algorithm", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-SignedHeaders", valid_602092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602094: Call_CreateDeployment_602082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_602094.validator(path, query, header, formData, body)
  let scheme = call_602094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602094.url(scheme.get, call_602094.host, call_602094.base,
                         call_602094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602094, url, valid)

proc call*(call_602095: Call_CreateDeployment_602082; restapiId: string;
          body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602096 = newJObject()
  var body_602097 = newJObject()
  add(path_602096, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602097 = body
  result = call_602095.call(path_602096, nil, nil, nil, body_602097)

var createDeployment* = Call_CreateDeployment_602082(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_602083, base: "/",
    url: url_CreateDeployment_602084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_602065 = ref object of OpenApiRestCall_601373
proc url_GetDeployments_602067(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_602066(path: JsonNode; query: JsonNode;
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
  var valid_602068 = path.getOrDefault("restapi_id")
  valid_602068 = validateParameter(valid_602068, JString, required = true,
                                 default = nil)
  if valid_602068 != nil:
    section.add "restapi_id", valid_602068
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_602069 = query.getOrDefault("limit")
  valid_602069 = validateParameter(valid_602069, JInt, required = false, default = nil)
  if valid_602069 != nil:
    section.add "limit", valid_602069
  var valid_602070 = query.getOrDefault("position")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "position", valid_602070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602071 = header.getOrDefault("X-Amz-Signature")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Signature", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Content-Sha256", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Date")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Date", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Credential")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Credential", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Security-Token")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Security-Token", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Algorithm")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Algorithm", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-SignedHeaders", valid_602077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602078: Call_GetDeployments_602065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_602078.validator(path, query, header, formData, body)
  let scheme = call_602078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602078.url(scheme.get, call_602078.host, call_602078.base,
                         call_602078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602078, url, valid)

proc call*(call_602079: Call_GetDeployments_602065; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602080 = newJObject()
  var query_602081 = newJObject()
  add(query_602081, "limit", newJInt(limit))
  add(query_602081, "position", newJString(position))
  add(path_602080, "restapi_id", newJString(restapiId))
  result = call_602079.call(path_602080, query_602081, nil, nil, nil)

var getDeployments* = Call_GetDeployments_602065(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_602066, base: "/", url: url_GetDeployments_602067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_602132 = ref object of OpenApiRestCall_601373
proc url_ImportDocumentationParts_602134(protocol: Scheme; host: string;
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

proc validate_ImportDocumentationParts_602133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_602135 = path.getOrDefault("restapi_id")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "restapi_id", valid_602135
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  section = newJObject()
  var valid_602136 = query.getOrDefault("failonwarnings")
  valid_602136 = validateParameter(valid_602136, JBool, required = false, default = nil)
  if valid_602136 != nil:
    section.add "failonwarnings", valid_602136
  var valid_602137 = query.getOrDefault("mode")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = newJString("merge"))
  if valid_602137 != nil:
    section.add "mode", valid_602137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602138 = header.getOrDefault("X-Amz-Signature")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Signature", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Content-Sha256", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Date")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Date", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Credential")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Credential", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Security-Token")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Security-Token", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Algorithm")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Algorithm", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-SignedHeaders", valid_602144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602146: Call_ImportDocumentationParts_602132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602146.validator(path, query, header, formData, body)
  let scheme = call_602146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602146.url(scheme.get, call_602146.host, call_602146.base,
                         call_602146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602146, url, valid)

proc call*(call_602147: Call_ImportDocumentationParts_602132; restapiId: string;
          body: JsonNode; failonwarnings: bool = false; mode: string = "merge"): Recallable =
  ## importDocumentationParts
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602148 = newJObject()
  var query_602149 = newJObject()
  var body_602150 = newJObject()
  add(query_602149, "failonwarnings", newJBool(failonwarnings))
  add(query_602149, "mode", newJString(mode))
  add(path_602148, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602150 = body
  result = call_602147.call(path_602148, query_602149, nil, nil, body_602150)

var importDocumentationParts* = Call_ImportDocumentationParts_602132(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_602133, base: "/",
    url: url_ImportDocumentationParts_602134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_602151 = ref object of OpenApiRestCall_601373
proc url_CreateDocumentationPart_602153(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocumentationPart_602152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_602154 = path.getOrDefault("restapi_id")
  valid_602154 = validateParameter(valid_602154, JString, required = true,
                                 default = nil)
  if valid_602154 != nil:
    section.add "restapi_id", valid_602154
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602155 = header.getOrDefault("X-Amz-Signature")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Signature", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Content-Sha256", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Date")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Date", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Credential")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Credential", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Security-Token")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Security-Token", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Algorithm")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Algorithm", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-SignedHeaders", valid_602161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602163: Call_CreateDocumentationPart_602151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602163.validator(path, query, header, formData, body)
  let scheme = call_602163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602163.url(scheme.get, call_602163.host, call_602163.base,
                         call_602163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602163, url, valid)

proc call*(call_602164: Call_CreateDocumentationPart_602151; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationPart
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602165 = newJObject()
  var body_602166 = newJObject()
  add(path_602165, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602166 = body
  result = call_602164.call(path_602165, nil, nil, nil, body_602166)

var createDocumentationPart* = Call_CreateDocumentationPart_602151(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_602152, base: "/",
    url: url_CreateDocumentationPart_602153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_602098 = ref object of OpenApiRestCall_601373
proc url_GetDocumentationParts_602100(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationParts_602099(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_602101 = path.getOrDefault("restapi_id")
  valid_602101 = validateParameter(valid_602101, JString, required = true,
                                 default = nil)
  if valid_602101 != nil:
    section.add "restapi_id", valid_602101
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
  var valid_602102 = query.getOrDefault("name")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "name", valid_602102
  var valid_602103 = query.getOrDefault("limit")
  valid_602103 = validateParameter(valid_602103, JInt, required = false, default = nil)
  if valid_602103 != nil:
    section.add "limit", valid_602103
  var valid_602117 = query.getOrDefault("locationStatus")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_602117 != nil:
    section.add "locationStatus", valid_602117
  var valid_602118 = query.getOrDefault("path")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "path", valid_602118
  var valid_602119 = query.getOrDefault("position")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "position", valid_602119
  var valid_602120 = query.getOrDefault("type")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = newJString("API"))
  if valid_602120 != nil:
    section.add "type", valid_602120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602121 = header.getOrDefault("X-Amz-Signature")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Signature", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Content-Sha256", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Date")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Date", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Credential")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Credential", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Algorithm")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Algorithm", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_GetDocumentationParts_602098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_GetDocumentationParts_602098; restapiId: string;
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
  var path_602130 = newJObject()
  var query_602131 = newJObject()
  add(query_602131, "name", newJString(name))
  add(query_602131, "limit", newJInt(limit))
  add(query_602131, "locationStatus", newJString(locationStatus))
  add(query_602131, "path", newJString(path))
  add(query_602131, "position", newJString(position))
  add(query_602131, "type", newJString(`type`))
  add(path_602130, "restapi_id", newJString(restapiId))
  result = call_602129.call(path_602130, query_602131, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_602098(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_602099, base: "/",
    url: url_GetDocumentationParts_602100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_602184 = ref object of OpenApiRestCall_601373
proc url_CreateDocumentationVersion_602186(protocol: Scheme; host: string;
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

proc validate_CreateDocumentationVersion_602185(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_602187 = path.getOrDefault("restapi_id")
  valid_602187 = validateParameter(valid_602187, JString, required = true,
                                 default = nil)
  if valid_602187 != nil:
    section.add "restapi_id", valid_602187
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602188 = header.getOrDefault("X-Amz-Signature")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Signature", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Content-Sha256", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Date")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Date", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Credential")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Credential", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Security-Token")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Security-Token", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Algorithm")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Algorithm", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-SignedHeaders", valid_602194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602196: Call_CreateDocumentationVersion_602184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602196.validator(path, query, header, formData, body)
  let scheme = call_602196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602196.url(scheme.get, call_602196.host, call_602196.base,
                         call_602196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602196, url, valid)

proc call*(call_602197: Call_CreateDocumentationVersion_602184; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationVersion
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602198 = newJObject()
  var body_602199 = newJObject()
  add(path_602198, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602199 = body
  result = call_602197.call(path_602198, nil, nil, nil, body_602199)

var createDocumentationVersion* = Call_CreateDocumentationVersion_602184(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_602185, base: "/",
    url: url_CreateDocumentationVersion_602186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_602167 = ref object of OpenApiRestCall_601373
proc url_GetDocumentationVersions_602169(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersions_602168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_602170 = path.getOrDefault("restapi_id")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = nil)
  if valid_602170 != nil:
    section.add "restapi_id", valid_602170
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_602171 = query.getOrDefault("limit")
  valid_602171 = validateParameter(valid_602171, JInt, required = false, default = nil)
  if valid_602171 != nil:
    section.add "limit", valid_602171
  var valid_602172 = query.getOrDefault("position")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "position", valid_602172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602173 = header.getOrDefault("X-Amz-Signature")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Signature", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Content-Sha256", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Date")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Date", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Credential")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Credential", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Security-Token")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Security-Token", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Algorithm")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Algorithm", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-SignedHeaders", valid_602179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602180: Call_GetDocumentationVersions_602167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602180.validator(path, query, header, formData, body)
  let scheme = call_602180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602180.url(scheme.get, call_602180.host, call_602180.base,
                         call_602180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602180, url, valid)

proc call*(call_602181: Call_GetDocumentationVersions_602167; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDocumentationVersions
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602182 = newJObject()
  var query_602183 = newJObject()
  add(query_602183, "limit", newJInt(limit))
  add(query_602183, "position", newJString(position))
  add(path_602182, "restapi_id", newJString(restapiId))
  result = call_602181.call(path_602182, query_602183, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_602167(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_602168, base: "/",
    url: url_GetDocumentationVersions_602169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_602215 = ref object of OpenApiRestCall_601373
proc url_CreateDomainName_602217(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainName_602216(path: JsonNode; query: JsonNode;
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
  var valid_602218 = header.getOrDefault("X-Amz-Signature")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Signature", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Content-Sha256", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Date")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Date", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Credential")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Credential", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Security-Token")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Security-Token", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Algorithm")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Algorithm", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-SignedHeaders", valid_602224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602226: Call_CreateDomainName_602215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_602226.validator(path, query, header, formData, body)
  let scheme = call_602226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602226.url(scheme.get, call_602226.host, call_602226.base,
                         call_602226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602226, url, valid)

proc call*(call_602227: Call_CreateDomainName_602215; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_602228 = newJObject()
  if body != nil:
    body_602228 = body
  result = call_602227.call(nil, nil, nil, nil, body_602228)

var createDomainName* = Call_CreateDomainName_602215(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_602216, base: "/",
    url: url_CreateDomainName_602217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_602200 = ref object of OpenApiRestCall_601373
proc url_GetDomainNames_602202(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainNames_602201(path: JsonNode; query: JsonNode;
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
  var valid_602203 = query.getOrDefault("limit")
  valid_602203 = validateParameter(valid_602203, JInt, required = false, default = nil)
  if valid_602203 != nil:
    section.add "limit", valid_602203
  var valid_602204 = query.getOrDefault("position")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "position", valid_602204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602205 = header.getOrDefault("X-Amz-Signature")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Signature", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Content-Sha256", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Date")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Date", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Credential")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Credential", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Security-Token")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Security-Token", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Algorithm")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Algorithm", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-SignedHeaders", valid_602211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602212: Call_GetDomainNames_602200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_602212.validator(path, query, header, formData, body)
  let scheme = call_602212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602212.url(scheme.get, call_602212.host, call_602212.base,
                         call_602212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602212, url, valid)

proc call*(call_602213: Call_GetDomainNames_602200; limit: int = 0;
          position: string = ""): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_602214 = newJObject()
  add(query_602214, "limit", newJInt(limit))
  add(query_602214, "position", newJString(position))
  result = call_602213.call(nil, query_602214, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_602200(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_602201, base: "/",
    url: url_GetDomainNames_602202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_602246 = ref object of OpenApiRestCall_601373
proc url_CreateModel_602248(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_602247(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602249 = path.getOrDefault("restapi_id")
  valid_602249 = validateParameter(valid_602249, JString, required = true,
                                 default = nil)
  if valid_602249 != nil:
    section.add "restapi_id", valid_602249
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602250 = header.getOrDefault("X-Amz-Signature")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Signature", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Date")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Date", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Security-Token")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Security-Token", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Algorithm")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Algorithm", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-SignedHeaders", valid_602256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_CreateModel_602246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602258, url, valid)

proc call*(call_602259: Call_CreateModel_602246; restapiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  ##   body: JObject (required)
  var path_602260 = newJObject()
  var body_602261 = newJObject()
  add(path_602260, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602261 = body
  result = call_602259.call(path_602260, nil, nil, nil, body_602261)

var createModel* = Call_CreateModel_602246(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_602247,
                                        base: "/", url: url_CreateModel_602248,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_602229 = ref object of OpenApiRestCall_601373
proc url_GetModels_602231(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_602230(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602232 = path.getOrDefault("restapi_id")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = nil)
  if valid_602232 != nil:
    section.add "restapi_id", valid_602232
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_602233 = query.getOrDefault("limit")
  valid_602233 = validateParameter(valid_602233, JInt, required = false, default = nil)
  if valid_602233 != nil:
    section.add "limit", valid_602233
  var valid_602234 = query.getOrDefault("position")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "position", valid_602234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602235 = header.getOrDefault("X-Amz-Signature")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Signature", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Content-Sha256", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Date")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Date", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Credential")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Credential", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Security-Token")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Security-Token", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Algorithm")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Algorithm", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-SignedHeaders", valid_602241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602242: Call_GetModels_602229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_602242.validator(path, query, header, formData, body)
  let scheme = call_602242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602242.url(scheme.get, call_602242.host, call_602242.base,
                         call_602242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602242, url, valid)

proc call*(call_602243: Call_GetModels_602229; restapiId: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602244 = newJObject()
  var query_602245 = newJObject()
  add(query_602245, "limit", newJInt(limit))
  add(query_602245, "position", newJString(position))
  add(path_602244, "restapi_id", newJString(restapiId))
  result = call_602243.call(path_602244, query_602245, nil, nil, nil)

var getModels* = Call_GetModels_602229(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_602230,
                                    base: "/", url: url_GetModels_602231,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_602279 = ref object of OpenApiRestCall_601373
proc url_CreateRequestValidator_602281(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRequestValidator_602280(path: JsonNode; query: JsonNode;
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
  var valid_602282 = path.getOrDefault("restapi_id")
  valid_602282 = validateParameter(valid_602282, JString, required = true,
                                 default = nil)
  if valid_602282 != nil:
    section.add "restapi_id", valid_602282
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602283 = header.getOrDefault("X-Amz-Signature")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Signature", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Content-Sha256", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Date")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Date", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Credential")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Credential", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Security-Token")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Security-Token", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Algorithm")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Algorithm", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-SignedHeaders", valid_602289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_CreateRequestValidator_602279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602291, url, valid)

proc call*(call_602292: Call_CreateRequestValidator_602279; restapiId: string;
          body: JsonNode): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602293 = newJObject()
  var body_602294 = newJObject()
  add(path_602293, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602294 = body
  result = call_602292.call(path_602293, nil, nil, nil, body_602294)

var createRequestValidator* = Call_CreateRequestValidator_602279(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_602280, base: "/",
    url: url_CreateRequestValidator_602281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_602262 = ref object of OpenApiRestCall_601373
proc url_GetRequestValidators_602264(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidators_602263(path: JsonNode; query: JsonNode;
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
  var valid_602265 = path.getOrDefault("restapi_id")
  valid_602265 = validateParameter(valid_602265, JString, required = true,
                                 default = nil)
  if valid_602265 != nil:
    section.add "restapi_id", valid_602265
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_602266 = query.getOrDefault("limit")
  valid_602266 = validateParameter(valid_602266, JInt, required = false, default = nil)
  if valid_602266 != nil:
    section.add "limit", valid_602266
  var valid_602267 = query.getOrDefault("position")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "position", valid_602267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602268 = header.getOrDefault("X-Amz-Signature")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Signature", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Content-Sha256", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Date")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Date", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Credential")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Credential", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Security-Token")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Security-Token", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Algorithm")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Algorithm", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-SignedHeaders", valid_602274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602275: Call_GetRequestValidators_602262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_602275.validator(path, query, header, formData, body)
  let scheme = call_602275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602275.url(scheme.get, call_602275.host, call_602275.base,
                         call_602275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602275, url, valid)

proc call*(call_602276: Call_GetRequestValidators_602262; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602277 = newJObject()
  var query_602278 = newJObject()
  add(query_602278, "limit", newJInt(limit))
  add(query_602278, "position", newJString(position))
  add(path_602277, "restapi_id", newJString(restapiId))
  result = call_602276.call(path_602277, query_602278, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_602262(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_602263, base: "/",
    url: url_GetRequestValidators_602264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_602295 = ref object of OpenApiRestCall_601373
proc url_CreateResource_602297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResource_602296(path: JsonNode; query: JsonNode;
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
  var valid_602298 = path.getOrDefault("restapi_id")
  valid_602298 = validateParameter(valid_602298, JString, required = true,
                                 default = nil)
  if valid_602298 != nil:
    section.add "restapi_id", valid_602298
  var valid_602299 = path.getOrDefault("parent_id")
  valid_602299 = validateParameter(valid_602299, JString, required = true,
                                 default = nil)
  if valid_602299 != nil:
    section.add "parent_id", valid_602299
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602300 = header.getOrDefault("X-Amz-Signature")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Signature", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Content-Sha256", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Date")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Date", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Credential")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Credential", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Security-Token")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Security-Token", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-SignedHeaders", valid_602306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602308: Call_CreateResource_602295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_602308.validator(path, query, header, formData, body)
  let scheme = call_602308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602308.url(scheme.get, call_602308.host, call_602308.base,
                         call_602308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602308, url, valid)

proc call*(call_602309: Call_CreateResource_602295; restapiId: string;
          body: JsonNode; parentId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  var path_602310 = newJObject()
  var body_602311 = newJObject()
  add(path_602310, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602311 = body
  add(path_602310, "parent_id", newJString(parentId))
  result = call_602309.call(path_602310, nil, nil, nil, body_602311)

var createResource* = Call_CreateResource_602295(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_602296, base: "/", url: url_CreateResource_602297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_602327 = ref object of OpenApiRestCall_601373
proc url_CreateRestApi_602329(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRestApi_602328(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Date")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Date", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Credential")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Credential", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Security-Token")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Security-Token", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-SignedHeaders", valid_602336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_CreateRestApi_602327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602338, url, valid)

proc call*(call_602339: Call_CreateRestApi_602327; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_602340 = newJObject()
  if body != nil:
    body_602340 = body
  result = call_602339.call(nil, nil, nil, nil, body_602340)

var createRestApi* = Call_CreateRestApi_602327(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_602328, base: "/", url: url_CreateRestApi_602329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_602312 = ref object of OpenApiRestCall_601373
proc url_GetRestApis_602314(protocol: Scheme; host: string; base: string;
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

proc validate_GetRestApis_602313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602315 = query.getOrDefault("limit")
  valid_602315 = validateParameter(valid_602315, JInt, required = false, default = nil)
  if valid_602315 != nil:
    section.add "limit", valid_602315
  var valid_602316 = query.getOrDefault("position")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "position", valid_602316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602317 = header.getOrDefault("X-Amz-Signature")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Signature", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Content-Sha256", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Date")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Date", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Credential")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Credential", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Security-Token")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Security-Token", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Algorithm")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Algorithm", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-SignedHeaders", valid_602323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602324: Call_GetRestApis_602312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_602324.validator(path, query, header, formData, body)
  let scheme = call_602324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602324.url(scheme.get, call_602324.host, call_602324.base,
                         call_602324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602324, url, valid)

proc call*(call_602325: Call_GetRestApis_602312; limit: int = 0; position: string = ""): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_602326 = newJObject()
  add(query_602326, "limit", newJInt(limit))
  add(query_602326, "position", newJString(position))
  result = call_602325.call(nil, query_602326, nil, nil, nil)

var getRestApis* = Call_GetRestApis_602312(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_602313,
                                        base: "/", url: url_GetRestApis_602314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_602357 = ref object of OpenApiRestCall_601373
proc url_CreateStage_602359(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_602358(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602360 = path.getOrDefault("restapi_id")
  valid_602360 = validateParameter(valid_602360, JString, required = true,
                                 default = nil)
  if valid_602360 != nil:
    section.add "restapi_id", valid_602360
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602361 = header.getOrDefault("X-Amz-Signature")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Signature", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Content-Sha256", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Date")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Date", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Credential")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Credential", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Security-Token")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Security-Token", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Algorithm")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Algorithm", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-SignedHeaders", valid_602367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602369: Call_CreateStage_602357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_602369.validator(path, query, header, formData, body)
  let scheme = call_602369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602369.url(scheme.get, call_602369.host, call_602369.base,
                         call_602369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602369, url, valid)

proc call*(call_602370: Call_CreateStage_602357; restapiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602371 = newJObject()
  var body_602372 = newJObject()
  add(path_602371, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602372 = body
  result = call_602370.call(path_602371, nil, nil, nil, body_602372)

var createStage* = Call_CreateStage_602357(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_602358,
                                        base: "/", url: url_CreateStage_602359,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_602341 = ref object of OpenApiRestCall_601373
proc url_GetStages_602343(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_602342(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602344 = path.getOrDefault("restapi_id")
  valid_602344 = validateParameter(valid_602344, JString, required = true,
                                 default = nil)
  if valid_602344 != nil:
    section.add "restapi_id", valid_602344
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_602345 = query.getOrDefault("deploymentId")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "deploymentId", valid_602345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602346 = header.getOrDefault("X-Amz-Signature")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Signature", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Content-Sha256", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Date")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Date", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Credential")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Credential", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Security-Token")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Security-Token", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Algorithm")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Algorithm", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-SignedHeaders", valid_602352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602353: Call_GetStages_602341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_602353.validator(path, query, header, formData, body)
  let scheme = call_602353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602353.url(scheme.get, call_602353.host, call_602353.base,
                         call_602353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602353, url, valid)

proc call*(call_602354: Call_GetStages_602341; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  var path_602355 = newJObject()
  var query_602356 = newJObject()
  add(path_602355, "restapi_id", newJString(restapiId))
  add(query_602356, "deploymentId", newJString(deploymentId))
  result = call_602354.call(path_602355, query_602356, nil, nil, nil)

var getStages* = Call_GetStages_602341(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_602342,
                                    base: "/", url: url_GetStages_602343,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_602389 = ref object of OpenApiRestCall_601373
proc url_CreateUsagePlan_602391(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlan_602390(path: JsonNode; query: JsonNode;
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
  var valid_602392 = header.getOrDefault("X-Amz-Signature")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Signature", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Content-Sha256", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Date")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Date", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Credential")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Credential", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Security-Token")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Security-Token", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Algorithm")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Algorithm", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-SignedHeaders", valid_602398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602400: Call_CreateUsagePlan_602389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_602400.validator(path, query, header, formData, body)
  let scheme = call_602400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602400.url(scheme.get, call_602400.host, call_602400.base,
                         call_602400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602400, url, valid)

proc call*(call_602401: Call_CreateUsagePlan_602389; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_602402 = newJObject()
  if body != nil:
    body_602402 = body
  result = call_602401.call(nil, nil, nil, nil, body_602402)

var createUsagePlan* = Call_CreateUsagePlan_602389(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_602390, base: "/",
    url: url_CreateUsagePlan_602391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_602373 = ref object of OpenApiRestCall_601373
proc url_GetUsagePlans_602375(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlans_602374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602376 = query.getOrDefault("limit")
  valid_602376 = validateParameter(valid_602376, JInt, required = false, default = nil)
  if valid_602376 != nil:
    section.add "limit", valid_602376
  var valid_602377 = query.getOrDefault("position")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "position", valid_602377
  var valid_602378 = query.getOrDefault("keyId")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "keyId", valid_602378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602379 = header.getOrDefault("X-Amz-Signature")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Signature", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Content-Sha256", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Date")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Date", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Credential")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Credential", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Security-Token")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Security-Token", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Algorithm")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Algorithm", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-SignedHeaders", valid_602385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602386: Call_GetUsagePlans_602373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_602386.validator(path, query, header, formData, body)
  let scheme = call_602386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602386.url(scheme.get, call_602386.host, call_602386.base,
                         call_602386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602386, url, valid)

proc call*(call_602387: Call_GetUsagePlans_602373; limit: int = 0;
          position: string = ""; keyId: string = ""): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  var query_602388 = newJObject()
  add(query_602388, "limit", newJInt(limit))
  add(query_602388, "position", newJString(position))
  add(query_602388, "keyId", newJString(keyId))
  result = call_602387.call(nil, query_602388, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_602373(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_602374, base: "/",
    url: url_GetUsagePlans_602375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_602421 = ref object of OpenApiRestCall_601373
proc url_CreateUsagePlanKey_602423(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlanKey_602422(path: JsonNode; query: JsonNode;
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
  var valid_602424 = path.getOrDefault("usageplanId")
  valid_602424 = validateParameter(valid_602424, JString, required = true,
                                 default = nil)
  if valid_602424 != nil:
    section.add "usageplanId", valid_602424
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602425 = header.getOrDefault("X-Amz-Signature")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Signature", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Content-Sha256", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Date")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Date", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Credential")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Credential", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Security-Token")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Security-Token", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Algorithm")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Algorithm", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-SignedHeaders", valid_602431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602433: Call_CreateUsagePlanKey_602421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_602433.validator(path, query, header, formData, body)
  let scheme = call_602433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602433.url(scheme.get, call_602433.host, call_602433.base,
                         call_602433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602433, url, valid)

proc call*(call_602434: Call_CreateUsagePlanKey_602421; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_602435 = newJObject()
  var body_602436 = newJObject()
  add(path_602435, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_602436 = body
  result = call_602434.call(path_602435, nil, nil, nil, body_602436)

var createUsagePlanKey* = Call_CreateUsagePlanKey_602421(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_602422, base: "/",
    url: url_CreateUsagePlanKey_602423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_602403 = ref object of OpenApiRestCall_601373
proc url_GetUsagePlanKeys_602405(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKeys_602404(path: JsonNode; query: JsonNode;
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
  var valid_602406 = path.getOrDefault("usageplanId")
  valid_602406 = validateParameter(valid_602406, JString, required = true,
                                 default = nil)
  if valid_602406 != nil:
    section.add "usageplanId", valid_602406
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_602407 = query.getOrDefault("name")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "name", valid_602407
  var valid_602408 = query.getOrDefault("limit")
  valid_602408 = validateParameter(valid_602408, JInt, required = false, default = nil)
  if valid_602408 != nil:
    section.add "limit", valid_602408
  var valid_602409 = query.getOrDefault("position")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "position", valid_602409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602410 = header.getOrDefault("X-Amz-Signature")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Signature", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Content-Sha256", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Date")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Date", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Credential")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Credential", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Security-Token")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Security-Token", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Algorithm")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Algorithm", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-SignedHeaders", valid_602416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602417: Call_GetUsagePlanKeys_602403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_602417.validator(path, query, header, formData, body)
  let scheme = call_602417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602417.url(scheme.get, call_602417.host, call_602417.base,
                         call_602417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602417, url, valid)

proc call*(call_602418: Call_GetUsagePlanKeys_602403; usageplanId: string;
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
  var path_602419 = newJObject()
  var query_602420 = newJObject()
  add(query_602420, "name", newJString(name))
  add(path_602419, "usageplanId", newJString(usageplanId))
  add(query_602420, "limit", newJInt(limit))
  add(query_602420, "position", newJString(position))
  result = call_602418.call(path_602419, query_602420, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_602403(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_602404,
    base: "/", url: url_GetUsagePlanKeys_602405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_602452 = ref object of OpenApiRestCall_601373
proc url_CreateVpcLink_602454(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVpcLink_602453(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602455 = header.getOrDefault("X-Amz-Signature")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Signature", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Content-Sha256", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Date")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Date", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Credential")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Credential", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Security-Token")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Security-Token", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Algorithm")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Algorithm", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-SignedHeaders", valid_602461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602463: Call_CreateVpcLink_602452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_602463.validator(path, query, header, formData, body)
  let scheme = call_602463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602463.url(scheme.get, call_602463.host, call_602463.base,
                         call_602463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602463, url, valid)

proc call*(call_602464: Call_CreateVpcLink_602452; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_602465 = newJObject()
  if body != nil:
    body_602465 = body
  result = call_602464.call(nil, nil, nil, nil, body_602465)

var createVpcLink* = Call_CreateVpcLink_602452(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_602453, base: "/", url: url_CreateVpcLink_602454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_602437 = ref object of OpenApiRestCall_601373
proc url_GetVpcLinks_602439(protocol: Scheme; host: string; base: string;
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

proc validate_GetVpcLinks_602438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602440 = query.getOrDefault("limit")
  valid_602440 = validateParameter(valid_602440, JInt, required = false, default = nil)
  if valid_602440 != nil:
    section.add "limit", valid_602440
  var valid_602441 = query.getOrDefault("position")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "position", valid_602441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Content-Sha256", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Date")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Date", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Algorithm")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Algorithm", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602449: Call_GetVpcLinks_602437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_602449.validator(path, query, header, formData, body)
  let scheme = call_602449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602449.url(scheme.get, call_602449.host, call_602449.base,
                         call_602449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602449, url, valid)

proc call*(call_602450: Call_GetVpcLinks_602437; limit: int = 0; position: string = ""): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_602451 = newJObject()
  add(query_602451, "limit", newJInt(limit))
  add(query_602451, "position", newJString(position))
  result = call_602450.call(nil, query_602451, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_602437(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_602438,
                                        base: "/", url: url_GetVpcLinks_602439,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_602466 = ref object of OpenApiRestCall_601373
proc url_GetApiKey_602468(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKey_602467(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602469 = path.getOrDefault("api_Key")
  valid_602469 = validateParameter(valid_602469, JString, required = true,
                                 default = nil)
  if valid_602469 != nil:
    section.add "api_Key", valid_602469
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_602470 = query.getOrDefault("includeValue")
  valid_602470 = validateParameter(valid_602470, JBool, required = false, default = nil)
  if valid_602470 != nil:
    section.add "includeValue", valid_602470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602471 = header.getOrDefault("X-Amz-Signature")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Signature", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Content-Sha256", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Date")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Date", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Credential")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Credential", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Security-Token")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Security-Token", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Algorithm")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Algorithm", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-SignedHeaders", valid_602477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602478: Call_GetApiKey_602466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_602478.validator(path, query, header, formData, body)
  let scheme = call_602478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602478.url(scheme.get, call_602478.host, call_602478.base,
                         call_602478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602478, url, valid)

proc call*(call_602479: Call_GetApiKey_602466; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_602480 = newJObject()
  var query_602481 = newJObject()
  add(query_602481, "includeValue", newJBool(includeValue))
  add(path_602480, "api_Key", newJString(apiKey))
  result = call_602479.call(path_602480, query_602481, nil, nil, nil)

var getApiKey* = Call_GetApiKey_602466(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_602467,
                                    base: "/", url: url_GetApiKey_602468,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_602496 = ref object of OpenApiRestCall_601373
proc url_UpdateApiKey_602498(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_602497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602499 = path.getOrDefault("api_Key")
  valid_602499 = validateParameter(valid_602499, JString, required = true,
                                 default = nil)
  if valid_602499 != nil:
    section.add "api_Key", valid_602499
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602500 = header.getOrDefault("X-Amz-Signature")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Signature", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Content-Sha256", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Date")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Date", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Credential")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Credential", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Security-Token")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Security-Token", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Algorithm")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Algorithm", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-SignedHeaders", valid_602506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602508: Call_UpdateApiKey_602496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_602508.validator(path, query, header, formData, body)
  let scheme = call_602508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602508.url(scheme.get, call_602508.host, call_602508.base,
                         call_602508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602508, url, valid)

proc call*(call_602509: Call_UpdateApiKey_602496; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_602510 = newJObject()
  var body_602511 = newJObject()
  add(path_602510, "api_Key", newJString(apiKey))
  if body != nil:
    body_602511 = body
  result = call_602509.call(path_602510, nil, nil, nil, body_602511)

var updateApiKey* = Call_UpdateApiKey_602496(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_602497, base: "/",
    url: url_UpdateApiKey_602498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_602482 = ref object of OpenApiRestCall_601373
proc url_DeleteApiKey_602484(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_602483(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602485 = path.getOrDefault("api_Key")
  valid_602485 = validateParameter(valid_602485, JString, required = true,
                                 default = nil)
  if valid_602485 != nil:
    section.add "api_Key", valid_602485
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602486 = header.getOrDefault("X-Amz-Signature")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Signature", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Content-Sha256", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Date")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Date", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Credential")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Credential", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Security-Token")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Security-Token", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Algorithm")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Algorithm", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-SignedHeaders", valid_602492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602493: Call_DeleteApiKey_602482; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_602493.validator(path, query, header, formData, body)
  let scheme = call_602493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602493.url(scheme.get, call_602493.host, call_602493.base,
                         call_602493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602493, url, valid)

proc call*(call_602494: Call_DeleteApiKey_602482; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_602495 = newJObject()
  add(path_602495, "api_Key", newJString(apiKey))
  result = call_602494.call(path_602495, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_602482(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_602483, base: "/",
    url: url_DeleteApiKey_602484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_602527 = ref object of OpenApiRestCall_601373
proc url_TestInvokeAuthorizer_602529(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeAuthorizer_602528(path: JsonNode; query: JsonNode;
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
  var valid_602530 = path.getOrDefault("restapi_id")
  valid_602530 = validateParameter(valid_602530, JString, required = true,
                                 default = nil)
  if valid_602530 != nil:
    section.add "restapi_id", valid_602530
  var valid_602531 = path.getOrDefault("authorizer_id")
  valid_602531 = validateParameter(valid_602531, JString, required = true,
                                 default = nil)
  if valid_602531 != nil:
    section.add "authorizer_id", valid_602531
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602532 = header.getOrDefault("X-Amz-Signature")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Signature", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Content-Sha256", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Date")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Date", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Credential")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Credential", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Security-Token")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Security-Token", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Algorithm")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Algorithm", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-SignedHeaders", valid_602538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602540: Call_TestInvokeAuthorizer_602527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_602540.validator(path, query, header, formData, body)
  let scheme = call_602540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602540.url(scheme.get, call_602540.host, call_602540.base,
                         call_602540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602540, url, valid)

proc call*(call_602541: Call_TestInvokeAuthorizer_602527; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  var path_602542 = newJObject()
  var body_602543 = newJObject()
  add(path_602542, "restapi_id", newJString(restapiId))
  add(path_602542, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_602543 = body
  result = call_602541.call(path_602542, nil, nil, nil, body_602543)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_602527(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_602528, base: "/",
    url: url_TestInvokeAuthorizer_602529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_602512 = ref object of OpenApiRestCall_601373
proc url_GetAuthorizer_602514(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_602513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602515 = path.getOrDefault("restapi_id")
  valid_602515 = validateParameter(valid_602515, JString, required = true,
                                 default = nil)
  if valid_602515 != nil:
    section.add "restapi_id", valid_602515
  var valid_602516 = path.getOrDefault("authorizer_id")
  valid_602516 = validateParameter(valid_602516, JString, required = true,
                                 default = nil)
  if valid_602516 != nil:
    section.add "authorizer_id", valid_602516
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602517 = header.getOrDefault("X-Amz-Signature")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Signature", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Content-Sha256", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Date")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Date", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Credential")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Credential", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Security-Token")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Security-Token", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Algorithm")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Algorithm", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-SignedHeaders", valid_602523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602524: Call_GetAuthorizer_602512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_602524.validator(path, query, header, formData, body)
  let scheme = call_602524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602524.url(scheme.get, call_602524.host, call_602524.base,
                         call_602524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602524, url, valid)

proc call*(call_602525: Call_GetAuthorizer_602512; restapiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_602526 = newJObject()
  add(path_602526, "restapi_id", newJString(restapiId))
  add(path_602526, "authorizer_id", newJString(authorizerId))
  result = call_602525.call(path_602526, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_602512(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_602513, base: "/", url: url_GetAuthorizer_602514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_602559 = ref object of OpenApiRestCall_601373
proc url_UpdateAuthorizer_602561(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_602560(path: JsonNode; query: JsonNode;
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
  var valid_602562 = path.getOrDefault("restapi_id")
  valid_602562 = validateParameter(valid_602562, JString, required = true,
                                 default = nil)
  if valid_602562 != nil:
    section.add "restapi_id", valid_602562
  var valid_602563 = path.getOrDefault("authorizer_id")
  valid_602563 = validateParameter(valid_602563, JString, required = true,
                                 default = nil)
  if valid_602563 != nil:
    section.add "authorizer_id", valid_602563
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602564 = header.getOrDefault("X-Amz-Signature")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Signature", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Content-Sha256", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Date")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Date", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Credential")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Credential", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Security-Token")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Security-Token", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-Algorithm")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-Algorithm", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-SignedHeaders", valid_602570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602572: Call_UpdateAuthorizer_602559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_602572.validator(path, query, header, formData, body)
  let scheme = call_602572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602572.url(scheme.get, call_602572.host, call_602572.base,
                         call_602572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602572, url, valid)

proc call*(call_602573: Call_UpdateAuthorizer_602559; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  var path_602574 = newJObject()
  var body_602575 = newJObject()
  add(path_602574, "restapi_id", newJString(restapiId))
  add(path_602574, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_602575 = body
  result = call_602573.call(path_602574, nil, nil, nil, body_602575)

var updateAuthorizer* = Call_UpdateAuthorizer_602559(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_602560, base: "/",
    url: url_UpdateAuthorizer_602561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_602544 = ref object of OpenApiRestCall_601373
proc url_DeleteAuthorizer_602546(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_602545(path: JsonNode; query: JsonNode;
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
  var valid_602547 = path.getOrDefault("restapi_id")
  valid_602547 = validateParameter(valid_602547, JString, required = true,
                                 default = nil)
  if valid_602547 != nil:
    section.add "restapi_id", valid_602547
  var valid_602548 = path.getOrDefault("authorizer_id")
  valid_602548 = validateParameter(valid_602548, JString, required = true,
                                 default = nil)
  if valid_602548 != nil:
    section.add "authorizer_id", valid_602548
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602549 = header.getOrDefault("X-Amz-Signature")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Signature", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Content-Sha256", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Date")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Date", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Credential")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Credential", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Security-Token")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Security-Token", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Algorithm")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Algorithm", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-SignedHeaders", valid_602555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602556: Call_DeleteAuthorizer_602544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_602556.validator(path, query, header, formData, body)
  let scheme = call_602556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602556.url(scheme.get, call_602556.host, call_602556.base,
                         call_602556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602556, url, valid)

proc call*(call_602557: Call_DeleteAuthorizer_602544; restapiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_602558 = newJObject()
  add(path_602558, "restapi_id", newJString(restapiId))
  add(path_602558, "authorizer_id", newJString(authorizerId))
  result = call_602557.call(path_602558, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_602544(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_602545, base: "/",
    url: url_DeleteAuthorizer_602546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_602576 = ref object of OpenApiRestCall_601373
proc url_GetBasePathMapping_602578(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMapping_602577(path: JsonNode; query: JsonNode;
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
  var valid_602579 = path.getOrDefault("base_path")
  valid_602579 = validateParameter(valid_602579, JString, required = true,
                                 default = nil)
  if valid_602579 != nil:
    section.add "base_path", valid_602579
  var valid_602580 = path.getOrDefault("domain_name")
  valid_602580 = validateParameter(valid_602580, JString, required = true,
                                 default = nil)
  if valid_602580 != nil:
    section.add "domain_name", valid_602580
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602581 = header.getOrDefault("X-Amz-Signature")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Signature", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Content-Sha256", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Date")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Date", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Credential")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Credential", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Security-Token")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Security-Token", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Algorithm")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Algorithm", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-SignedHeaders", valid_602587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602588: Call_GetBasePathMapping_602576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_602588.validator(path, query, header, formData, body)
  let scheme = call_602588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602588.url(scheme.get, call_602588.host, call_602588.base,
                         call_602588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602588, url, valid)

proc call*(call_602589: Call_GetBasePathMapping_602576; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_602590 = newJObject()
  add(path_602590, "base_path", newJString(basePath))
  add(path_602590, "domain_name", newJString(domainName))
  result = call_602589.call(path_602590, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_602576(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_602577, base: "/",
    url: url_GetBasePathMapping_602578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_602606 = ref object of OpenApiRestCall_601373
proc url_UpdateBasePathMapping_602608(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBasePathMapping_602607(path: JsonNode; query: JsonNode;
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
  var valid_602609 = path.getOrDefault("base_path")
  valid_602609 = validateParameter(valid_602609, JString, required = true,
                                 default = nil)
  if valid_602609 != nil:
    section.add "base_path", valid_602609
  var valid_602610 = path.getOrDefault("domain_name")
  valid_602610 = validateParameter(valid_602610, JString, required = true,
                                 default = nil)
  if valid_602610 != nil:
    section.add "domain_name", valid_602610
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602611 = header.getOrDefault("X-Amz-Signature")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Signature", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Content-Sha256", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Date")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Date", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Credential")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Credential", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Security-Token")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Security-Token", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Algorithm")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Algorithm", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-SignedHeaders", valid_602617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602619: Call_UpdateBasePathMapping_602606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_602619.validator(path, query, header, formData, body)
  let scheme = call_602619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602619.url(scheme.get, call_602619.host, call_602619.base,
                         call_602619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602619, url, valid)

proc call*(call_602620: Call_UpdateBasePathMapping_602606; basePath: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  var path_602621 = newJObject()
  var body_602622 = newJObject()
  add(path_602621, "base_path", newJString(basePath))
  if body != nil:
    body_602622 = body
  add(path_602621, "domain_name", newJString(domainName))
  result = call_602620.call(path_602621, nil, nil, nil, body_602622)

var updateBasePathMapping* = Call_UpdateBasePathMapping_602606(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_602607, base: "/",
    url: url_UpdateBasePathMapping_602608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_602591 = ref object of OpenApiRestCall_601373
proc url_DeleteBasePathMapping_602593(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBasePathMapping_602592(path: JsonNode; query: JsonNode;
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
  var valid_602594 = path.getOrDefault("base_path")
  valid_602594 = validateParameter(valid_602594, JString, required = true,
                                 default = nil)
  if valid_602594 != nil:
    section.add "base_path", valid_602594
  var valid_602595 = path.getOrDefault("domain_name")
  valid_602595 = validateParameter(valid_602595, JString, required = true,
                                 default = nil)
  if valid_602595 != nil:
    section.add "domain_name", valid_602595
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602596 = header.getOrDefault("X-Amz-Signature")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Signature", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Content-Sha256", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Date")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Date", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Credential")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Credential", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Security-Token")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Security-Token", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Algorithm")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Algorithm", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-SignedHeaders", valid_602602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602603: Call_DeleteBasePathMapping_602591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_602603.validator(path, query, header, formData, body)
  let scheme = call_602603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602603.url(scheme.get, call_602603.host, call_602603.base,
                         call_602603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602603, url, valid)

proc call*(call_602604: Call_DeleteBasePathMapping_602591; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_602605 = newJObject()
  add(path_602605, "base_path", newJString(basePath))
  add(path_602605, "domain_name", newJString(domainName))
  result = call_602604.call(path_602605, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_602591(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_602592, base: "/",
    url: url_DeleteBasePathMapping_602593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_602623 = ref object of OpenApiRestCall_601373
proc url_GetClientCertificate_602625(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificate_602624(path: JsonNode; query: JsonNode;
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
  var valid_602626 = path.getOrDefault("clientcertificate_id")
  valid_602626 = validateParameter(valid_602626, JString, required = true,
                                 default = nil)
  if valid_602626 != nil:
    section.add "clientcertificate_id", valid_602626
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602627 = header.getOrDefault("X-Amz-Signature")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Signature", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Content-Sha256", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Date")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Date", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Credential")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Credential", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Security-Token")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Security-Token", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Algorithm")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Algorithm", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-SignedHeaders", valid_602633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602634: Call_GetClientCertificate_602623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_602634.validator(path, query, header, formData, body)
  let scheme = call_602634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602634.url(scheme.get, call_602634.host, call_602634.base,
                         call_602634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602634, url, valid)

proc call*(call_602635: Call_GetClientCertificate_602623;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_602636 = newJObject()
  add(path_602636, "clientcertificate_id", newJString(clientcertificateId))
  result = call_602635.call(path_602636, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_602623(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_602624, base: "/",
    url: url_GetClientCertificate_602625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_602651 = ref object of OpenApiRestCall_601373
proc url_UpdateClientCertificate_602653(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClientCertificate_602652(path: JsonNode; query: JsonNode;
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
  var valid_602654 = path.getOrDefault("clientcertificate_id")
  valid_602654 = validateParameter(valid_602654, JString, required = true,
                                 default = nil)
  if valid_602654 != nil:
    section.add "clientcertificate_id", valid_602654
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602655 = header.getOrDefault("X-Amz-Signature")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Signature", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Content-Sha256", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Date")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Date", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Credential")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Credential", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Security-Token")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Security-Token", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Algorithm")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Algorithm", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-SignedHeaders", valid_602661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602663: Call_UpdateClientCertificate_602651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_602663.validator(path, query, header, formData, body)
  let scheme = call_602663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602663.url(scheme.get, call_602663.host, call_602663.base,
                         call_602663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602663, url, valid)

proc call*(call_602664: Call_UpdateClientCertificate_602651;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_602665 = newJObject()
  var body_602666 = newJObject()
  add(path_602665, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_602666 = body
  result = call_602664.call(path_602665, nil, nil, nil, body_602666)

var updateClientCertificate* = Call_UpdateClientCertificate_602651(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_602652, base: "/",
    url: url_UpdateClientCertificate_602653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_602637 = ref object of OpenApiRestCall_601373
proc url_DeleteClientCertificate_602639(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClientCertificate_602638(path: JsonNode; query: JsonNode;
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
  var valid_602640 = path.getOrDefault("clientcertificate_id")
  valid_602640 = validateParameter(valid_602640, JString, required = true,
                                 default = nil)
  if valid_602640 != nil:
    section.add "clientcertificate_id", valid_602640
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602641 = header.getOrDefault("X-Amz-Signature")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Signature", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Content-Sha256", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Date")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Date", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Credential")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Credential", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Security-Token")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Security-Token", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Algorithm")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Algorithm", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-SignedHeaders", valid_602647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602648: Call_DeleteClientCertificate_602637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_602648.validator(path, query, header, formData, body)
  let scheme = call_602648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602648.url(scheme.get, call_602648.host, call_602648.base,
                         call_602648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602648, url, valid)

proc call*(call_602649: Call_DeleteClientCertificate_602637;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_602650 = newJObject()
  add(path_602650, "clientcertificate_id", newJString(clientcertificateId))
  result = call_602649.call(path_602650, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_602637(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_602638, base: "/",
    url: url_DeleteClientCertificate_602639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_602667 = ref object of OpenApiRestCall_601373
proc url_GetDeployment_602669(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_602668(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602670 = path.getOrDefault("deployment_id")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = nil)
  if valid_602670 != nil:
    section.add "deployment_id", valid_602670
  var valid_602671 = path.getOrDefault("restapi_id")
  valid_602671 = validateParameter(valid_602671, JString, required = true,
                                 default = nil)
  if valid_602671 != nil:
    section.add "restapi_id", valid_602671
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_602672 = query.getOrDefault("embed")
  valid_602672 = validateParameter(valid_602672, JArray, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "embed", valid_602672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602673 = header.getOrDefault("X-Amz-Signature")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Signature", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Content-Sha256", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Date")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Date", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Credential")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Credential", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Security-Token")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Security-Token", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Algorithm")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Algorithm", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-SignedHeaders", valid_602679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602680: Call_GetDeployment_602667; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_602680.validator(path, query, header, formData, body)
  let scheme = call_602680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602680.url(scheme.get, call_602680.host, call_602680.base,
                         call_602680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602680, url, valid)

proc call*(call_602681: Call_GetDeployment_602667; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  var path_602682 = newJObject()
  var query_602683 = newJObject()
  add(path_602682, "deployment_id", newJString(deploymentId))
  add(path_602682, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_602683.add "embed", embed
  result = call_602681.call(path_602682, query_602683, nil, nil, nil)

var getDeployment* = Call_GetDeployment_602667(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_602668, base: "/", url: url_GetDeployment_602669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_602699 = ref object of OpenApiRestCall_601373
proc url_UpdateDeployment_602701(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_602700(path: JsonNode; query: JsonNode;
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
  var valid_602702 = path.getOrDefault("deployment_id")
  valid_602702 = validateParameter(valid_602702, JString, required = true,
                                 default = nil)
  if valid_602702 != nil:
    section.add "deployment_id", valid_602702
  var valid_602703 = path.getOrDefault("restapi_id")
  valid_602703 = validateParameter(valid_602703, JString, required = true,
                                 default = nil)
  if valid_602703 != nil:
    section.add "restapi_id", valid_602703
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602704 = header.getOrDefault("X-Amz-Signature")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Signature", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Content-Sha256", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Date")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Date", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Credential")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Credential", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Security-Token")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Security-Token", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Algorithm")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Algorithm", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-SignedHeaders", valid_602710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602712: Call_UpdateDeployment_602699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_602712.validator(path, query, header, formData, body)
  let scheme = call_602712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602712.url(scheme.get, call_602712.host, call_602712.base,
                         call_602712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602712, url, valid)

proc call*(call_602713: Call_UpdateDeployment_602699; deploymentId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602714 = newJObject()
  var body_602715 = newJObject()
  add(path_602714, "deployment_id", newJString(deploymentId))
  add(path_602714, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602715 = body
  result = call_602713.call(path_602714, nil, nil, nil, body_602715)

var updateDeployment* = Call_UpdateDeployment_602699(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_602700, base: "/",
    url: url_UpdateDeployment_602701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_602684 = ref object of OpenApiRestCall_601373
proc url_DeleteDeployment_602686(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_602685(path: JsonNode; query: JsonNode;
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
  var valid_602687 = path.getOrDefault("deployment_id")
  valid_602687 = validateParameter(valid_602687, JString, required = true,
                                 default = nil)
  if valid_602687 != nil:
    section.add "deployment_id", valid_602687
  var valid_602688 = path.getOrDefault("restapi_id")
  valid_602688 = validateParameter(valid_602688, JString, required = true,
                                 default = nil)
  if valid_602688 != nil:
    section.add "restapi_id", valid_602688
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602689 = header.getOrDefault("X-Amz-Signature")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Signature", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Content-Sha256", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Date")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Date", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Credential")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Credential", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Security-Token")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Security-Token", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Algorithm")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Algorithm", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-SignedHeaders", valid_602695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602696: Call_DeleteDeployment_602684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_602696.validator(path, query, header, formData, body)
  let scheme = call_602696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602696.url(scheme.get, call_602696.host, call_602696.base,
                         call_602696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602696, url, valid)

proc call*(call_602697: Call_DeleteDeployment_602684; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602698 = newJObject()
  add(path_602698, "deployment_id", newJString(deploymentId))
  add(path_602698, "restapi_id", newJString(restapiId))
  result = call_602697.call(path_602698, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_602684(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_602685, base: "/",
    url: url_DeleteDeployment_602686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_602716 = ref object of OpenApiRestCall_601373
proc url_GetDocumentationPart_602718(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationPart_602717(path: JsonNode; query: JsonNode;
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
  var valid_602719 = path.getOrDefault("part_id")
  valid_602719 = validateParameter(valid_602719, JString, required = true,
                                 default = nil)
  if valid_602719 != nil:
    section.add "part_id", valid_602719
  var valid_602720 = path.getOrDefault("restapi_id")
  valid_602720 = validateParameter(valid_602720, JString, required = true,
                                 default = nil)
  if valid_602720 != nil:
    section.add "restapi_id", valid_602720
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602721 = header.getOrDefault("X-Amz-Signature")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Signature", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Content-Sha256", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Date")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Date", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Credential")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Credential", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Security-Token")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Security-Token", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Algorithm")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Algorithm", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-SignedHeaders", valid_602727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602728: Call_GetDocumentationPart_602716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602728.validator(path, query, header, formData, body)
  let scheme = call_602728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602728.url(scheme.get, call_602728.host, call_602728.base,
                         call_602728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602728, url, valid)

proc call*(call_602729: Call_GetDocumentationPart_602716; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602730 = newJObject()
  add(path_602730, "part_id", newJString(partId))
  add(path_602730, "restapi_id", newJString(restapiId))
  result = call_602729.call(path_602730, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_602716(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_602717, base: "/",
    url: url_GetDocumentationPart_602718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_602746 = ref object of OpenApiRestCall_601373
proc url_UpdateDocumentationPart_602748(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentationPart_602747(path: JsonNode; query: JsonNode;
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
  var valid_602749 = path.getOrDefault("part_id")
  valid_602749 = validateParameter(valid_602749, JString, required = true,
                                 default = nil)
  if valid_602749 != nil:
    section.add "part_id", valid_602749
  var valid_602750 = path.getOrDefault("restapi_id")
  valid_602750 = validateParameter(valid_602750, JString, required = true,
                                 default = nil)
  if valid_602750 != nil:
    section.add "restapi_id", valid_602750
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602751 = header.getOrDefault("X-Amz-Signature")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Signature", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Content-Sha256", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Date")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Date", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Credential")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Credential", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Security-Token")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Security-Token", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Algorithm")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Algorithm", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-SignedHeaders", valid_602757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602759: Call_UpdateDocumentationPart_602746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602759.validator(path, query, header, formData, body)
  let scheme = call_602759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602759.url(scheme.get, call_602759.host, call_602759.base,
                         call_602759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602759, url, valid)

proc call*(call_602760: Call_UpdateDocumentationPart_602746; partId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_602761 = newJObject()
  var body_602762 = newJObject()
  add(path_602761, "part_id", newJString(partId))
  add(path_602761, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602762 = body
  result = call_602760.call(path_602761, nil, nil, nil, body_602762)

var updateDocumentationPart* = Call_UpdateDocumentationPart_602746(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_602747, base: "/",
    url: url_UpdateDocumentationPart_602748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_602731 = ref object of OpenApiRestCall_601373
proc url_DeleteDocumentationPart_602733(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocumentationPart_602732(path: JsonNode; query: JsonNode;
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
  var valid_602734 = path.getOrDefault("part_id")
  valid_602734 = validateParameter(valid_602734, JString, required = true,
                                 default = nil)
  if valid_602734 != nil:
    section.add "part_id", valid_602734
  var valid_602735 = path.getOrDefault("restapi_id")
  valid_602735 = validateParameter(valid_602735, JString, required = true,
                                 default = nil)
  if valid_602735 != nil:
    section.add "restapi_id", valid_602735
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602736 = header.getOrDefault("X-Amz-Signature")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Signature", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Content-Sha256", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Date")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Date", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Credential")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Credential", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Security-Token")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Security-Token", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Algorithm")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Algorithm", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-SignedHeaders", valid_602742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602743: Call_DeleteDocumentationPart_602731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602743.validator(path, query, header, formData, body)
  let scheme = call_602743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602743.url(scheme.get, call_602743.host, call_602743.base,
                         call_602743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602743, url, valid)

proc call*(call_602744: Call_DeleteDocumentationPart_602731; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602745 = newJObject()
  add(path_602745, "part_id", newJString(partId))
  add(path_602745, "restapi_id", newJString(restapiId))
  result = call_602744.call(path_602745, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_602731(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_602732, base: "/",
    url: url_DeleteDocumentationPart_602733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_602763 = ref object of OpenApiRestCall_601373
proc url_GetDocumentationVersion_602765(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationVersion_602764(path: JsonNode; query: JsonNode;
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
  var valid_602766 = path.getOrDefault("doc_version")
  valid_602766 = validateParameter(valid_602766, JString, required = true,
                                 default = nil)
  if valid_602766 != nil:
    section.add "doc_version", valid_602766
  var valid_602767 = path.getOrDefault("restapi_id")
  valid_602767 = validateParameter(valid_602767, JString, required = true,
                                 default = nil)
  if valid_602767 != nil:
    section.add "restapi_id", valid_602767
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602768 = header.getOrDefault("X-Amz-Signature")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Signature", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Content-Sha256", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Date")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Date", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Credential")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Credential", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Security-Token")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Security-Token", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Algorithm")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Algorithm", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-SignedHeaders", valid_602774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602775: Call_GetDocumentationVersion_602763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602775.validator(path, query, header, formData, body)
  let scheme = call_602775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602775.url(scheme.get, call_602775.host, call_602775.base,
                         call_602775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602775, url, valid)

proc call*(call_602776: Call_GetDocumentationVersion_602763; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602777 = newJObject()
  add(path_602777, "doc_version", newJString(docVersion))
  add(path_602777, "restapi_id", newJString(restapiId))
  result = call_602776.call(path_602777, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_602763(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_602764, base: "/",
    url: url_GetDocumentationVersion_602765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_602793 = ref object of OpenApiRestCall_601373
proc url_UpdateDocumentationVersion_602795(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentationVersion_602794(path: JsonNode; query: JsonNode;
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
  var valid_602796 = path.getOrDefault("doc_version")
  valid_602796 = validateParameter(valid_602796, JString, required = true,
                                 default = nil)
  if valid_602796 != nil:
    section.add "doc_version", valid_602796
  var valid_602797 = path.getOrDefault("restapi_id")
  valid_602797 = validateParameter(valid_602797, JString, required = true,
                                 default = nil)
  if valid_602797 != nil:
    section.add "restapi_id", valid_602797
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602798 = header.getOrDefault("X-Amz-Signature")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Signature", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Content-Sha256", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Date")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Date", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Credential")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Credential", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Security-Token")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Security-Token", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Algorithm")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Algorithm", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-SignedHeaders", valid_602804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602806: Call_UpdateDocumentationVersion_602793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602806.validator(path, query, header, formData, body)
  let scheme = call_602806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602806.url(scheme.get, call_602806.host, call_602806.base,
                         call_602806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602806, url, valid)

proc call*(call_602807: Call_UpdateDocumentationVersion_602793; docVersion: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  ##   body: JObject (required)
  var path_602808 = newJObject()
  var body_602809 = newJObject()
  add(path_602808, "doc_version", newJString(docVersion))
  add(path_602808, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602809 = body
  result = call_602807.call(path_602808, nil, nil, nil, body_602809)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_602793(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_602794, base: "/",
    url: url_UpdateDocumentationVersion_602795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_602778 = ref object of OpenApiRestCall_601373
proc url_DeleteDocumentationVersion_602780(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentationVersion_602779(path: JsonNode; query: JsonNode;
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
  var valid_602781 = path.getOrDefault("doc_version")
  valid_602781 = validateParameter(valid_602781, JString, required = true,
                                 default = nil)
  if valid_602781 != nil:
    section.add "doc_version", valid_602781
  var valid_602782 = path.getOrDefault("restapi_id")
  valid_602782 = validateParameter(valid_602782, JString, required = true,
                                 default = nil)
  if valid_602782 != nil:
    section.add "restapi_id", valid_602782
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602783 = header.getOrDefault("X-Amz-Signature")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Signature", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Content-Sha256", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Date")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Date", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Credential")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Credential", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Security-Token")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Security-Token", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Algorithm")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Algorithm", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-SignedHeaders", valid_602789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602790: Call_DeleteDocumentationVersion_602778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602790.validator(path, query, header, formData, body)
  let scheme = call_602790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602790.url(scheme.get, call_602790.host, call_602790.base,
                         call_602790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602790, url, valid)

proc call*(call_602791: Call_DeleteDocumentationVersion_602778; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602792 = newJObject()
  add(path_602792, "doc_version", newJString(docVersion))
  add(path_602792, "restapi_id", newJString(restapiId))
  result = call_602791.call(path_602792, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_602778(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_602779, base: "/",
    url: url_DeleteDocumentationVersion_602780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_602810 = ref object of OpenApiRestCall_601373
proc url_GetDomainName_602812(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_602811(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602813 = path.getOrDefault("domain_name")
  valid_602813 = validateParameter(valid_602813, JString, required = true,
                                 default = nil)
  if valid_602813 != nil:
    section.add "domain_name", valid_602813
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602814 = header.getOrDefault("X-Amz-Signature")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Signature", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-Content-Sha256", valid_602815
  var valid_602816 = header.getOrDefault("X-Amz-Date")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "X-Amz-Date", valid_602816
  var valid_602817 = header.getOrDefault("X-Amz-Credential")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Credential", valid_602817
  var valid_602818 = header.getOrDefault("X-Amz-Security-Token")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Security-Token", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Algorithm")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Algorithm", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-SignedHeaders", valid_602820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602821: Call_GetDomainName_602810; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_602821.validator(path, query, header, formData, body)
  let scheme = call_602821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602821.url(scheme.get, call_602821.host, call_602821.base,
                         call_602821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602821, url, valid)

proc call*(call_602822: Call_GetDomainName_602810; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_602823 = newJObject()
  add(path_602823, "domain_name", newJString(domainName))
  result = call_602822.call(path_602823, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_602810(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_602811,
    base: "/", url: url_GetDomainName_602812, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_602838 = ref object of OpenApiRestCall_601373
proc url_UpdateDomainName_602840(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_602839(path: JsonNode; query: JsonNode;
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
  var valid_602841 = path.getOrDefault("domain_name")
  valid_602841 = validateParameter(valid_602841, JString, required = true,
                                 default = nil)
  if valid_602841 != nil:
    section.add "domain_name", valid_602841
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602842 = header.getOrDefault("X-Amz-Signature")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-Signature", valid_602842
  var valid_602843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Content-Sha256", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Date")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Date", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Credential")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Credential", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Security-Token")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Security-Token", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Algorithm")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Algorithm", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-SignedHeaders", valid_602848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602850: Call_UpdateDomainName_602838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_602850.validator(path, query, header, formData, body)
  let scheme = call_602850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602850.url(scheme.get, call_602850.host, call_602850.base,
                         call_602850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602850, url, valid)

proc call*(call_602851: Call_UpdateDomainName_602838; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  var path_602852 = newJObject()
  var body_602853 = newJObject()
  if body != nil:
    body_602853 = body
  add(path_602852, "domain_name", newJString(domainName))
  result = call_602851.call(path_602852, nil, nil, nil, body_602853)

var updateDomainName* = Call_UpdateDomainName_602838(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_602839,
    base: "/", url: url_UpdateDomainName_602840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_602824 = ref object of OpenApiRestCall_601373
proc url_DeleteDomainName_602826(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_602825(path: JsonNode; query: JsonNode;
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
  var valid_602827 = path.getOrDefault("domain_name")
  valid_602827 = validateParameter(valid_602827, JString, required = true,
                                 default = nil)
  if valid_602827 != nil:
    section.add "domain_name", valid_602827
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602828 = header.getOrDefault("X-Amz-Signature")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Signature", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Content-Sha256", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Date")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Date", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-Credential")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Credential", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Security-Token")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Security-Token", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Algorithm")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Algorithm", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-SignedHeaders", valid_602834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602835: Call_DeleteDomainName_602824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_602835.validator(path, query, header, formData, body)
  let scheme = call_602835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602835.url(scheme.get, call_602835.host, call_602835.base,
                         call_602835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602835, url, valid)

proc call*(call_602836: Call_DeleteDomainName_602824; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_602837 = newJObject()
  add(path_602837, "domain_name", newJString(domainName))
  result = call_602836.call(path_602837, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_602824(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_602825,
    base: "/", url: url_DeleteDomainName_602826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_602869 = ref object of OpenApiRestCall_601373
proc url_PutGatewayResponse_602871(protocol: Scheme; host: string; base: string;
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

proc validate_PutGatewayResponse_602870(path: JsonNode; query: JsonNode;
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
  var valid_602872 = path.getOrDefault("response_type")
  valid_602872 = validateParameter(valid_602872, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_602872 != nil:
    section.add "response_type", valid_602872
  var valid_602873 = path.getOrDefault("restapi_id")
  valid_602873 = validateParameter(valid_602873, JString, required = true,
                                 default = nil)
  if valid_602873 != nil:
    section.add "restapi_id", valid_602873
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602874 = header.getOrDefault("X-Amz-Signature")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Signature", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Content-Sha256", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Date")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Date", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Credential")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Credential", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Security-Token")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Security-Token", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Algorithm")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Algorithm", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-SignedHeaders", valid_602880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602882: Call_PutGatewayResponse_602869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_602882.validator(path, query, header, formData, body)
  let scheme = call_602882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602882.url(scheme.get, call_602882.host, call_602882.base,
                         call_602882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602882, url, valid)

proc call*(call_602883: Call_PutGatewayResponse_602869; restapiId: string;
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
  var path_602884 = newJObject()
  var body_602885 = newJObject()
  add(path_602884, "response_type", newJString(responseType))
  add(path_602884, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602885 = body
  result = call_602883.call(path_602884, nil, nil, nil, body_602885)

var putGatewayResponse* = Call_PutGatewayResponse_602869(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_602870, base: "/",
    url: url_PutGatewayResponse_602871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_602854 = ref object of OpenApiRestCall_601373
proc url_GetGatewayResponse_602856(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponse_602855(path: JsonNode; query: JsonNode;
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
  var valid_602857 = path.getOrDefault("response_type")
  valid_602857 = validateParameter(valid_602857, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_602857 != nil:
    section.add "response_type", valid_602857
  var valid_602858 = path.getOrDefault("restapi_id")
  valid_602858 = validateParameter(valid_602858, JString, required = true,
                                 default = nil)
  if valid_602858 != nil:
    section.add "restapi_id", valid_602858
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602859 = header.getOrDefault("X-Amz-Signature")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Signature", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Content-Sha256", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Date")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Date", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Credential")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Credential", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Security-Token")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Security-Token", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Algorithm")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Algorithm", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-SignedHeaders", valid_602865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602866: Call_GetGatewayResponse_602854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_602866.validator(path, query, header, formData, body)
  let scheme = call_602866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602866.url(scheme.get, call_602866.host, call_602866.base,
                         call_602866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602866, url, valid)

proc call*(call_602867: Call_GetGatewayResponse_602854; restapiId: string;
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
  var path_602868 = newJObject()
  add(path_602868, "response_type", newJString(responseType))
  add(path_602868, "restapi_id", newJString(restapiId))
  result = call_602867.call(path_602868, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_602854(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_602855, base: "/",
    url: url_GetGatewayResponse_602856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_602901 = ref object of OpenApiRestCall_601373
proc url_UpdateGatewayResponse_602903(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayResponse_602902(path: JsonNode; query: JsonNode;
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
  var valid_602904 = path.getOrDefault("response_type")
  valid_602904 = validateParameter(valid_602904, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_602904 != nil:
    section.add "response_type", valid_602904
  var valid_602905 = path.getOrDefault("restapi_id")
  valid_602905 = validateParameter(valid_602905, JString, required = true,
                                 default = nil)
  if valid_602905 != nil:
    section.add "restapi_id", valid_602905
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602906 = header.getOrDefault("X-Amz-Signature")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Signature", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Content-Sha256", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Date")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Date", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Credential")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Credential", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Security-Token")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Security-Token", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Algorithm")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Algorithm", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-SignedHeaders", valid_602912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_UpdateGatewayResponse_602901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602914, url, valid)

proc call*(call_602915: Call_UpdateGatewayResponse_602901; restapiId: string;
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
  var path_602916 = newJObject()
  var body_602917 = newJObject()
  add(path_602916, "response_type", newJString(responseType))
  add(path_602916, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602917 = body
  result = call_602915.call(path_602916, nil, nil, nil, body_602917)

var updateGatewayResponse* = Call_UpdateGatewayResponse_602901(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_602902, base: "/",
    url: url_UpdateGatewayResponse_602903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_602886 = ref object of OpenApiRestCall_601373
proc url_DeleteGatewayResponse_602888(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayResponse_602887(path: JsonNode; query: JsonNode;
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
  var valid_602889 = path.getOrDefault("response_type")
  valid_602889 = validateParameter(valid_602889, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_602889 != nil:
    section.add "response_type", valid_602889
  var valid_602890 = path.getOrDefault("restapi_id")
  valid_602890 = validateParameter(valid_602890, JString, required = true,
                                 default = nil)
  if valid_602890 != nil:
    section.add "restapi_id", valid_602890
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602891 = header.getOrDefault("X-Amz-Signature")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Signature", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Content-Sha256", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Date")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Date", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Credential")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Credential", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Security-Token")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Security-Token", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Algorithm")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Algorithm", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-SignedHeaders", valid_602897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602898: Call_DeleteGatewayResponse_602886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_602898.validator(path, query, header, formData, body)
  let scheme = call_602898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602898.url(scheme.get, call_602898.host, call_602898.base,
                         call_602898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602898, url, valid)

proc call*(call_602899: Call_DeleteGatewayResponse_602886; restapiId: string;
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
  var path_602900 = newJObject()
  add(path_602900, "response_type", newJString(responseType))
  add(path_602900, "restapi_id", newJString(restapiId))
  result = call_602899.call(path_602900, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_602886(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_602887, base: "/",
    url: url_DeleteGatewayResponse_602888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_602934 = ref object of OpenApiRestCall_601373
proc url_PutIntegration_602936(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegration_602935(path: JsonNode; query: JsonNode;
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
  var valid_602937 = path.getOrDefault("restapi_id")
  valid_602937 = validateParameter(valid_602937, JString, required = true,
                                 default = nil)
  if valid_602937 != nil:
    section.add "restapi_id", valid_602937
  var valid_602938 = path.getOrDefault("resource_id")
  valid_602938 = validateParameter(valid_602938, JString, required = true,
                                 default = nil)
  if valid_602938 != nil:
    section.add "resource_id", valid_602938
  var valid_602939 = path.getOrDefault("http_method")
  valid_602939 = validateParameter(valid_602939, JString, required = true,
                                 default = nil)
  if valid_602939 != nil:
    section.add "http_method", valid_602939
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602940 = header.getOrDefault("X-Amz-Signature")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Signature", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Content-Sha256", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Date")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Date", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-Credential")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-Credential", valid_602943
  var valid_602944 = header.getOrDefault("X-Amz-Security-Token")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-Security-Token", valid_602944
  var valid_602945 = header.getOrDefault("X-Amz-Algorithm")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Algorithm", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-SignedHeaders", valid_602946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602948: Call_PutIntegration_602934; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_602948.validator(path, query, header, formData, body)
  let scheme = call_602948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602948.url(scheme.get, call_602948.host, call_602948.base,
                         call_602948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602948, url, valid)

proc call*(call_602949: Call_PutIntegration_602934; restapiId: string;
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
  var path_602950 = newJObject()
  var body_602951 = newJObject()
  add(path_602950, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602951 = body
  add(path_602950, "resource_id", newJString(resourceId))
  add(path_602950, "http_method", newJString(httpMethod))
  result = call_602949.call(path_602950, nil, nil, nil, body_602951)

var putIntegration* = Call_PutIntegration_602934(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_602935, base: "/", url: url_PutIntegration_602936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_602918 = ref object of OpenApiRestCall_601373
proc url_GetIntegration_602920(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_602919(path: JsonNode; query: JsonNode;
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
  var valid_602921 = path.getOrDefault("restapi_id")
  valid_602921 = validateParameter(valid_602921, JString, required = true,
                                 default = nil)
  if valid_602921 != nil:
    section.add "restapi_id", valid_602921
  var valid_602922 = path.getOrDefault("resource_id")
  valid_602922 = validateParameter(valid_602922, JString, required = true,
                                 default = nil)
  if valid_602922 != nil:
    section.add "resource_id", valid_602922
  var valid_602923 = path.getOrDefault("http_method")
  valid_602923 = validateParameter(valid_602923, JString, required = true,
                                 default = nil)
  if valid_602923 != nil:
    section.add "http_method", valid_602923
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602924 = header.getOrDefault("X-Amz-Signature")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Signature", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Content-Sha256", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Date")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Date", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Credential")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Credential", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Security-Token")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Security-Token", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Algorithm")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Algorithm", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-SignedHeaders", valid_602930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602931: Call_GetIntegration_602918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_602931.validator(path, query, header, formData, body)
  let scheme = call_602931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602931.url(scheme.get, call_602931.host, call_602931.base,
                         call_602931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602931, url, valid)

proc call*(call_602932: Call_GetIntegration_602918; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  var path_602933 = newJObject()
  add(path_602933, "restapi_id", newJString(restapiId))
  add(path_602933, "resource_id", newJString(resourceId))
  add(path_602933, "http_method", newJString(httpMethod))
  result = call_602932.call(path_602933, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_602918(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_602919, base: "/", url: url_GetIntegration_602920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_602968 = ref object of OpenApiRestCall_601373
proc url_UpdateIntegration_602970(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_602969(path: JsonNode; query: JsonNode;
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
  var valid_602971 = path.getOrDefault("restapi_id")
  valid_602971 = validateParameter(valid_602971, JString, required = true,
                                 default = nil)
  if valid_602971 != nil:
    section.add "restapi_id", valid_602971
  var valid_602972 = path.getOrDefault("resource_id")
  valid_602972 = validateParameter(valid_602972, JString, required = true,
                                 default = nil)
  if valid_602972 != nil:
    section.add "resource_id", valid_602972
  var valid_602973 = path.getOrDefault("http_method")
  valid_602973 = validateParameter(valid_602973, JString, required = true,
                                 default = nil)
  if valid_602973 != nil:
    section.add "http_method", valid_602973
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602974 = header.getOrDefault("X-Amz-Signature")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-Signature", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Content-Sha256", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Date")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Date", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Credential")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Credential", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Security-Token")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Security-Token", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-Algorithm")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-Algorithm", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-SignedHeaders", valid_602980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602982: Call_UpdateIntegration_602968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_602982.validator(path, query, header, formData, body)
  let scheme = call_602982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602982.url(scheme.get, call_602982.host, call_602982.base,
                         call_602982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602982, url, valid)

proc call*(call_602983: Call_UpdateIntegration_602968; restapiId: string;
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
  var path_602984 = newJObject()
  var body_602985 = newJObject()
  add(path_602984, "restapi_id", newJString(restapiId))
  if body != nil:
    body_602985 = body
  add(path_602984, "resource_id", newJString(resourceId))
  add(path_602984, "http_method", newJString(httpMethod))
  result = call_602983.call(path_602984, nil, nil, nil, body_602985)

var updateIntegration* = Call_UpdateIntegration_602968(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_602969, base: "/",
    url: url_UpdateIntegration_602970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_602952 = ref object of OpenApiRestCall_601373
proc url_DeleteIntegration_602954(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_602953(path: JsonNode; query: JsonNode;
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
  var valid_602955 = path.getOrDefault("restapi_id")
  valid_602955 = validateParameter(valid_602955, JString, required = true,
                                 default = nil)
  if valid_602955 != nil:
    section.add "restapi_id", valid_602955
  var valid_602956 = path.getOrDefault("resource_id")
  valid_602956 = validateParameter(valid_602956, JString, required = true,
                                 default = nil)
  if valid_602956 != nil:
    section.add "resource_id", valid_602956
  var valid_602957 = path.getOrDefault("http_method")
  valid_602957 = validateParameter(valid_602957, JString, required = true,
                                 default = nil)
  if valid_602957 != nil:
    section.add "http_method", valid_602957
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602958 = header.getOrDefault("X-Amz-Signature")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Signature", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Content-Sha256", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Date")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Date", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Credential")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Credential", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Security-Token")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Security-Token", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Algorithm")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Algorithm", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-SignedHeaders", valid_602964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602965: Call_DeleteIntegration_602952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_602965.validator(path, query, header, formData, body)
  let scheme = call_602965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602965.url(scheme.get, call_602965.host, call_602965.base,
                         call_602965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602965, url, valid)

proc call*(call_602966: Call_DeleteIntegration_602952; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  var path_602967 = newJObject()
  add(path_602967, "restapi_id", newJString(restapiId))
  add(path_602967, "resource_id", newJString(resourceId))
  add(path_602967, "http_method", newJString(httpMethod))
  result = call_602966.call(path_602967, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_602952(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_602953, base: "/",
    url: url_DeleteIntegration_602954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_603003 = ref object of OpenApiRestCall_601373
proc url_PutIntegrationResponse_603005(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegrationResponse_603004(path: JsonNode; query: JsonNode;
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
  var valid_603006 = path.getOrDefault("status_code")
  valid_603006 = validateParameter(valid_603006, JString, required = true,
                                 default = nil)
  if valid_603006 != nil:
    section.add "status_code", valid_603006
  var valid_603007 = path.getOrDefault("restapi_id")
  valid_603007 = validateParameter(valid_603007, JString, required = true,
                                 default = nil)
  if valid_603007 != nil:
    section.add "restapi_id", valid_603007
  var valid_603008 = path.getOrDefault("resource_id")
  valid_603008 = validateParameter(valid_603008, JString, required = true,
                                 default = nil)
  if valid_603008 != nil:
    section.add "resource_id", valid_603008
  var valid_603009 = path.getOrDefault("http_method")
  valid_603009 = validateParameter(valid_603009, JString, required = true,
                                 default = nil)
  if valid_603009 != nil:
    section.add "http_method", valid_603009
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603010 = header.getOrDefault("X-Amz-Signature")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-Signature", valid_603010
  var valid_603011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-Content-Sha256", valid_603011
  var valid_603012 = header.getOrDefault("X-Amz-Date")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "X-Amz-Date", valid_603012
  var valid_603013 = header.getOrDefault("X-Amz-Credential")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "X-Amz-Credential", valid_603013
  var valid_603014 = header.getOrDefault("X-Amz-Security-Token")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "X-Amz-Security-Token", valid_603014
  var valid_603015 = header.getOrDefault("X-Amz-Algorithm")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "X-Amz-Algorithm", valid_603015
  var valid_603016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-SignedHeaders", valid_603016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603018: Call_PutIntegrationResponse_603003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_603018.validator(path, query, header, formData, body)
  let scheme = call_603018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603018.url(scheme.get, call_603018.host, call_603018.base,
                         call_603018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603018, url, valid)

proc call*(call_603019: Call_PutIntegrationResponse_603003; statusCode: string;
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
  var path_603020 = newJObject()
  var body_603021 = newJObject()
  add(path_603020, "status_code", newJString(statusCode))
  add(path_603020, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603021 = body
  add(path_603020, "resource_id", newJString(resourceId))
  add(path_603020, "http_method", newJString(httpMethod))
  result = call_603019.call(path_603020, nil, nil, nil, body_603021)

var putIntegrationResponse* = Call_PutIntegrationResponse_603003(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_603004, base: "/",
    url: url_PutIntegrationResponse_603005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_602986 = ref object of OpenApiRestCall_601373
proc url_GetIntegrationResponse_602988(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_602987(path: JsonNode; query: JsonNode;
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
  var valid_602989 = path.getOrDefault("status_code")
  valid_602989 = validateParameter(valid_602989, JString, required = true,
                                 default = nil)
  if valid_602989 != nil:
    section.add "status_code", valid_602989
  var valid_602990 = path.getOrDefault("restapi_id")
  valid_602990 = validateParameter(valid_602990, JString, required = true,
                                 default = nil)
  if valid_602990 != nil:
    section.add "restapi_id", valid_602990
  var valid_602991 = path.getOrDefault("resource_id")
  valid_602991 = validateParameter(valid_602991, JString, required = true,
                                 default = nil)
  if valid_602991 != nil:
    section.add "resource_id", valid_602991
  var valid_602992 = path.getOrDefault("http_method")
  valid_602992 = validateParameter(valid_602992, JString, required = true,
                                 default = nil)
  if valid_602992 != nil:
    section.add "http_method", valid_602992
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602993 = header.getOrDefault("X-Amz-Signature")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Signature", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-Content-Sha256", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-Date")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-Date", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-Credential")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Credential", valid_602996
  var valid_602997 = header.getOrDefault("X-Amz-Security-Token")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-Security-Token", valid_602997
  var valid_602998 = header.getOrDefault("X-Amz-Algorithm")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "X-Amz-Algorithm", valid_602998
  var valid_602999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-SignedHeaders", valid_602999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603000: Call_GetIntegrationResponse_602986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_603000.validator(path, query, header, formData, body)
  let scheme = call_603000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603000.url(scheme.get, call_603000.host, call_603000.base,
                         call_603000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603000, url, valid)

proc call*(call_603001: Call_GetIntegrationResponse_602986; statusCode: string;
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
  var path_603002 = newJObject()
  add(path_603002, "status_code", newJString(statusCode))
  add(path_603002, "restapi_id", newJString(restapiId))
  add(path_603002, "resource_id", newJString(resourceId))
  add(path_603002, "http_method", newJString(httpMethod))
  result = call_603001.call(path_603002, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_602986(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_602987, base: "/",
    url: url_GetIntegrationResponse_602988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_603039 = ref object of OpenApiRestCall_601373
proc url_UpdateIntegrationResponse_603041(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_603040(path: JsonNode; query: JsonNode;
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
  var valid_603042 = path.getOrDefault("status_code")
  valid_603042 = validateParameter(valid_603042, JString, required = true,
                                 default = nil)
  if valid_603042 != nil:
    section.add "status_code", valid_603042
  var valid_603043 = path.getOrDefault("restapi_id")
  valid_603043 = validateParameter(valid_603043, JString, required = true,
                                 default = nil)
  if valid_603043 != nil:
    section.add "restapi_id", valid_603043
  var valid_603044 = path.getOrDefault("resource_id")
  valid_603044 = validateParameter(valid_603044, JString, required = true,
                                 default = nil)
  if valid_603044 != nil:
    section.add "resource_id", valid_603044
  var valid_603045 = path.getOrDefault("http_method")
  valid_603045 = validateParameter(valid_603045, JString, required = true,
                                 default = nil)
  if valid_603045 != nil:
    section.add "http_method", valid_603045
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603046 = header.getOrDefault("X-Amz-Signature")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Signature", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Content-Sha256", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Date")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Date", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Security-Token")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Security-Token", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Algorithm")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Algorithm", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-SignedHeaders", valid_603052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603054: Call_UpdateIntegrationResponse_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_603054.validator(path, query, header, formData, body)
  let scheme = call_603054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603054.url(scheme.get, call_603054.host, call_603054.base,
                         call_603054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603054, url, valid)

proc call*(call_603055: Call_UpdateIntegrationResponse_603039; statusCode: string;
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
  var path_603056 = newJObject()
  var body_603057 = newJObject()
  add(path_603056, "status_code", newJString(statusCode))
  add(path_603056, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603057 = body
  add(path_603056, "resource_id", newJString(resourceId))
  add(path_603056, "http_method", newJString(httpMethod))
  result = call_603055.call(path_603056, nil, nil, nil, body_603057)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_603039(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_603040, base: "/",
    url: url_UpdateIntegrationResponse_603041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_603022 = ref object of OpenApiRestCall_601373
proc url_DeleteIntegrationResponse_603024(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_603023(path: JsonNode; query: JsonNode;
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
  var valid_603025 = path.getOrDefault("status_code")
  valid_603025 = validateParameter(valid_603025, JString, required = true,
                                 default = nil)
  if valid_603025 != nil:
    section.add "status_code", valid_603025
  var valid_603026 = path.getOrDefault("restapi_id")
  valid_603026 = validateParameter(valid_603026, JString, required = true,
                                 default = nil)
  if valid_603026 != nil:
    section.add "restapi_id", valid_603026
  var valid_603027 = path.getOrDefault("resource_id")
  valid_603027 = validateParameter(valid_603027, JString, required = true,
                                 default = nil)
  if valid_603027 != nil:
    section.add "resource_id", valid_603027
  var valid_603028 = path.getOrDefault("http_method")
  valid_603028 = validateParameter(valid_603028, JString, required = true,
                                 default = nil)
  if valid_603028 != nil:
    section.add "http_method", valid_603028
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603029 = header.getOrDefault("X-Amz-Signature")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Signature", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Content-Sha256", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Date")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Date", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Credential")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Credential", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Security-Token")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Security-Token", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Algorithm")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Algorithm", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-SignedHeaders", valid_603035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603036: Call_DeleteIntegrationResponse_603022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_603036.validator(path, query, header, formData, body)
  let scheme = call_603036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603036.url(scheme.get, call_603036.host, call_603036.base,
                         call_603036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603036, url, valid)

proc call*(call_603037: Call_DeleteIntegrationResponse_603022; statusCode: string;
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
  var path_603038 = newJObject()
  add(path_603038, "status_code", newJString(statusCode))
  add(path_603038, "restapi_id", newJString(restapiId))
  add(path_603038, "resource_id", newJString(resourceId))
  add(path_603038, "http_method", newJString(httpMethod))
  result = call_603037.call(path_603038, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_603022(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_603023, base: "/",
    url: url_DeleteIntegrationResponse_603024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_603074 = ref object of OpenApiRestCall_601373
proc url_PutMethod_603076(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutMethod_603075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603077 = path.getOrDefault("restapi_id")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = nil)
  if valid_603077 != nil:
    section.add "restapi_id", valid_603077
  var valid_603078 = path.getOrDefault("resource_id")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = nil)
  if valid_603078 != nil:
    section.add "resource_id", valid_603078
  var valid_603079 = path.getOrDefault("http_method")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = nil)
  if valid_603079 != nil:
    section.add "http_method", valid_603079
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Content-Sha256", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Security-Token")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Security-Token", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-SignedHeaders", valid_603086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_PutMethod_603074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603088, url, valid)

proc call*(call_603089: Call_PutMethod_603074; restapiId: string; body: JsonNode;
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
  var path_603090 = newJObject()
  var body_603091 = newJObject()
  add(path_603090, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603091 = body
  add(path_603090, "resource_id", newJString(resourceId))
  add(path_603090, "http_method", newJString(httpMethod))
  result = call_603089.call(path_603090, nil, nil, nil, body_603091)

var putMethod* = Call_PutMethod_603074(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_603075,
                                    base: "/", url: url_PutMethod_603076,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_603092 = ref object of OpenApiRestCall_601373
proc url_TestInvokeMethod_603094(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeMethod_603093(path: JsonNode; query: JsonNode;
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
  var valid_603095 = path.getOrDefault("restapi_id")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "restapi_id", valid_603095
  var valid_603096 = path.getOrDefault("resource_id")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = nil)
  if valid_603096 != nil:
    section.add "resource_id", valid_603096
  var valid_603097 = path.getOrDefault("http_method")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = nil)
  if valid_603097 != nil:
    section.add "http_method", valid_603097
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603098 = header.getOrDefault("X-Amz-Signature")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Signature", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Content-Sha256", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Credential")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Credential", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Security-Token")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Security-Token", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_TestInvokeMethod_603092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603106, url, valid)

proc call*(call_603107: Call_TestInvokeMethod_603092; restapiId: string;
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
  var path_603108 = newJObject()
  var body_603109 = newJObject()
  add(path_603108, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603109 = body
  add(path_603108, "resource_id", newJString(resourceId))
  add(path_603108, "http_method", newJString(httpMethod))
  result = call_603107.call(path_603108, nil, nil, nil, body_603109)

var testInvokeMethod* = Call_TestInvokeMethod_603092(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_603093, base: "/",
    url: url_TestInvokeMethod_603094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_603058 = ref object of OpenApiRestCall_601373
proc url_GetMethod_603060(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMethod_603059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603061 = path.getOrDefault("restapi_id")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = nil)
  if valid_603061 != nil:
    section.add "restapi_id", valid_603061
  var valid_603062 = path.getOrDefault("resource_id")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = nil)
  if valid_603062 != nil:
    section.add "resource_id", valid_603062
  var valid_603063 = path.getOrDefault("http_method")
  valid_603063 = validateParameter(valid_603063, JString, required = true,
                                 default = nil)
  if valid_603063 != nil:
    section.add "http_method", valid_603063
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603064 = header.getOrDefault("X-Amz-Signature")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Signature", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Content-Sha256", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Date")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Date", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Credential")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Credential", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Security-Token")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Security-Token", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Algorithm")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Algorithm", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-SignedHeaders", valid_603070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_GetMethod_603058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603071, url, valid)

proc call*(call_603072: Call_GetMethod_603058; restapiId: string; resourceId: string;
          httpMethod: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  var path_603073 = newJObject()
  add(path_603073, "restapi_id", newJString(restapiId))
  add(path_603073, "resource_id", newJString(resourceId))
  add(path_603073, "http_method", newJString(httpMethod))
  result = call_603072.call(path_603073, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_603058(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_603059,
                                    base: "/", url: url_GetMethod_603060,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_603126 = ref object of OpenApiRestCall_601373
proc url_UpdateMethod_603128(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethod_603127(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603129 = path.getOrDefault("restapi_id")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = nil)
  if valid_603129 != nil:
    section.add "restapi_id", valid_603129
  var valid_603130 = path.getOrDefault("resource_id")
  valid_603130 = validateParameter(valid_603130, JString, required = true,
                                 default = nil)
  if valid_603130 != nil:
    section.add "resource_id", valid_603130
  var valid_603131 = path.getOrDefault("http_method")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = nil)
  if valid_603131 != nil:
    section.add "http_method", valid_603131
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603132 = header.getOrDefault("X-Amz-Signature")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Signature", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Content-Sha256", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Date")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Date", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Credential")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Credential", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Algorithm")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Algorithm", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603140: Call_UpdateMethod_603126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_603140.validator(path, query, header, formData, body)
  let scheme = call_603140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603140.url(scheme.get, call_603140.host, call_603140.base,
                         call_603140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603140, url, valid)

proc call*(call_603141: Call_UpdateMethod_603126; restapiId: string; body: JsonNode;
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
  var path_603142 = newJObject()
  var body_603143 = newJObject()
  add(path_603142, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603143 = body
  add(path_603142, "resource_id", newJString(resourceId))
  add(path_603142, "http_method", newJString(httpMethod))
  result = call_603141.call(path_603142, nil, nil, nil, body_603143)

var updateMethod* = Call_UpdateMethod_603126(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_603127, base: "/", url: url_UpdateMethod_603128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_603110 = ref object of OpenApiRestCall_601373
proc url_DeleteMethod_603112(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethod_603111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603113 = path.getOrDefault("restapi_id")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = nil)
  if valid_603113 != nil:
    section.add "restapi_id", valid_603113
  var valid_603114 = path.getOrDefault("resource_id")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = nil)
  if valid_603114 != nil:
    section.add "resource_id", valid_603114
  var valid_603115 = path.getOrDefault("http_method")
  valid_603115 = validateParameter(valid_603115, JString, required = true,
                                 default = nil)
  if valid_603115 != nil:
    section.add "http_method", valid_603115
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603116 = header.getOrDefault("X-Amz-Signature")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Signature", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Content-Sha256", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Date")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Date", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Security-Token")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Security-Token", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-SignedHeaders", valid_603122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603123: Call_DeleteMethod_603110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_603123.validator(path, query, header, formData, body)
  let scheme = call_603123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603123.url(scheme.get, call_603123.host, call_603123.base,
                         call_603123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603123, url, valid)

proc call*(call_603124: Call_DeleteMethod_603110; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_603125 = newJObject()
  add(path_603125, "restapi_id", newJString(restapiId))
  add(path_603125, "resource_id", newJString(resourceId))
  add(path_603125, "http_method", newJString(httpMethod))
  result = call_603124.call(path_603125, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_603110(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_603111, base: "/", url: url_DeleteMethod_603112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_603161 = ref object of OpenApiRestCall_601373
proc url_PutMethodResponse_603163(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethodResponse_603162(path: JsonNode; query: JsonNode;
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
  var valid_603164 = path.getOrDefault("status_code")
  valid_603164 = validateParameter(valid_603164, JString, required = true,
                                 default = nil)
  if valid_603164 != nil:
    section.add "status_code", valid_603164
  var valid_603165 = path.getOrDefault("restapi_id")
  valid_603165 = validateParameter(valid_603165, JString, required = true,
                                 default = nil)
  if valid_603165 != nil:
    section.add "restapi_id", valid_603165
  var valid_603166 = path.getOrDefault("resource_id")
  valid_603166 = validateParameter(valid_603166, JString, required = true,
                                 default = nil)
  if valid_603166 != nil:
    section.add "resource_id", valid_603166
  var valid_603167 = path.getOrDefault("http_method")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = nil)
  if valid_603167 != nil:
    section.add "http_method", valid_603167
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Credential")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Credential", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603176: Call_PutMethodResponse_603161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_603176.validator(path, query, header, formData, body)
  let scheme = call_603176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603176.url(scheme.get, call_603176.host, call_603176.base,
                         call_603176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603176, url, valid)

proc call*(call_603177: Call_PutMethodResponse_603161; statusCode: string;
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
  var path_603178 = newJObject()
  var body_603179 = newJObject()
  add(path_603178, "status_code", newJString(statusCode))
  add(path_603178, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603179 = body
  add(path_603178, "resource_id", newJString(resourceId))
  add(path_603178, "http_method", newJString(httpMethod))
  result = call_603177.call(path_603178, nil, nil, nil, body_603179)

var putMethodResponse* = Call_PutMethodResponse_603161(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_603162, base: "/",
    url: url_PutMethodResponse_603163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_603144 = ref object of OpenApiRestCall_601373
proc url_GetMethodResponse_603146(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethodResponse_603145(path: JsonNode; query: JsonNode;
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
  var valid_603147 = path.getOrDefault("status_code")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = nil)
  if valid_603147 != nil:
    section.add "status_code", valid_603147
  var valid_603148 = path.getOrDefault("restapi_id")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = nil)
  if valid_603148 != nil:
    section.add "restapi_id", valid_603148
  var valid_603149 = path.getOrDefault("resource_id")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = nil)
  if valid_603149 != nil:
    section.add "resource_id", valid_603149
  var valid_603150 = path.getOrDefault("http_method")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = nil)
  if valid_603150 != nil:
    section.add "http_method", valid_603150
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603151 = header.getOrDefault("X-Amz-Signature")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Signature", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Content-Sha256", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Date")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Date", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Algorithm")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Algorithm", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-SignedHeaders", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603158: Call_GetMethodResponse_603144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_603158.validator(path, query, header, formData, body)
  let scheme = call_603158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603158.url(scheme.get, call_603158.host, call_603158.base,
                         call_603158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603158, url, valid)

proc call*(call_603159: Call_GetMethodResponse_603144; statusCode: string;
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
  var path_603160 = newJObject()
  add(path_603160, "status_code", newJString(statusCode))
  add(path_603160, "restapi_id", newJString(restapiId))
  add(path_603160, "resource_id", newJString(resourceId))
  add(path_603160, "http_method", newJString(httpMethod))
  result = call_603159.call(path_603160, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_603144(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_603145, base: "/",
    url: url_GetMethodResponse_603146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_603197 = ref object of OpenApiRestCall_601373
proc url_UpdateMethodResponse_603199(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethodResponse_603198(path: JsonNode; query: JsonNode;
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
  var valid_603200 = path.getOrDefault("status_code")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = nil)
  if valid_603200 != nil:
    section.add "status_code", valid_603200
  var valid_603201 = path.getOrDefault("restapi_id")
  valid_603201 = validateParameter(valid_603201, JString, required = true,
                                 default = nil)
  if valid_603201 != nil:
    section.add "restapi_id", valid_603201
  var valid_603202 = path.getOrDefault("resource_id")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = nil)
  if valid_603202 != nil:
    section.add "resource_id", valid_603202
  var valid_603203 = path.getOrDefault("http_method")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = nil)
  if valid_603203 != nil:
    section.add "http_method", valid_603203
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Content-Sha256", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Credential")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Credential", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603212: Call_UpdateMethodResponse_603197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_603212.validator(path, query, header, formData, body)
  let scheme = call_603212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603212.url(scheme.get, call_603212.host, call_603212.base,
                         call_603212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603212, url, valid)

proc call*(call_603213: Call_UpdateMethodResponse_603197; statusCode: string;
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
  var path_603214 = newJObject()
  var body_603215 = newJObject()
  add(path_603214, "status_code", newJString(statusCode))
  add(path_603214, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603215 = body
  add(path_603214, "resource_id", newJString(resourceId))
  add(path_603214, "http_method", newJString(httpMethod))
  result = call_603213.call(path_603214, nil, nil, nil, body_603215)

var updateMethodResponse* = Call_UpdateMethodResponse_603197(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_603198, base: "/",
    url: url_UpdateMethodResponse_603199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_603180 = ref object of OpenApiRestCall_601373
proc url_DeleteMethodResponse_603182(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethodResponse_603181(path: JsonNode; query: JsonNode;
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
  var valid_603183 = path.getOrDefault("status_code")
  valid_603183 = validateParameter(valid_603183, JString, required = true,
                                 default = nil)
  if valid_603183 != nil:
    section.add "status_code", valid_603183
  var valid_603184 = path.getOrDefault("restapi_id")
  valid_603184 = validateParameter(valid_603184, JString, required = true,
                                 default = nil)
  if valid_603184 != nil:
    section.add "restapi_id", valid_603184
  var valid_603185 = path.getOrDefault("resource_id")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "resource_id", valid_603185
  var valid_603186 = path.getOrDefault("http_method")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = nil)
  if valid_603186 != nil:
    section.add "http_method", valid_603186
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603187 = header.getOrDefault("X-Amz-Signature")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Signature", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Content-Sha256", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Date")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Date", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Credential")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Credential", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Security-Token")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Security-Token", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Algorithm")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Algorithm", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-SignedHeaders", valid_603193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603194: Call_DeleteMethodResponse_603180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_603194.validator(path, query, header, formData, body)
  let scheme = call_603194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603194.url(scheme.get, call_603194.host, call_603194.base,
                         call_603194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603194, url, valid)

proc call*(call_603195: Call_DeleteMethodResponse_603180; statusCode: string;
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
  var path_603196 = newJObject()
  add(path_603196, "status_code", newJString(statusCode))
  add(path_603196, "restapi_id", newJString(restapiId))
  add(path_603196, "resource_id", newJString(resourceId))
  add(path_603196, "http_method", newJString(httpMethod))
  result = call_603195.call(path_603196, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_603180(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_603181, base: "/",
    url: url_DeleteMethodResponse_603182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_603216 = ref object of OpenApiRestCall_601373
proc url_GetModel_603218(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_603217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603219 = path.getOrDefault("model_name")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "model_name", valid_603219
  var valid_603220 = path.getOrDefault("restapi_id")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = nil)
  if valid_603220 != nil:
    section.add "restapi_id", valid_603220
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_603221 = query.getOrDefault("flatten")
  valid_603221 = validateParameter(valid_603221, JBool, required = false, default = nil)
  if valid_603221 != nil:
    section.add "flatten", valid_603221
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603222 = header.getOrDefault("X-Amz-Signature")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Signature", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Content-Sha256", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Date")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Date", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Credential")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Credential", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Algorithm")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Algorithm", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-SignedHeaders", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_GetModel_603216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603229, url, valid)

proc call*(call_603230: Call_GetModel_603216; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_603231 = newJObject()
  var query_603232 = newJObject()
  add(query_603232, "flatten", newJBool(flatten))
  add(path_603231, "model_name", newJString(modelName))
  add(path_603231, "restapi_id", newJString(restapiId))
  result = call_603230.call(path_603231, query_603232, nil, nil, nil)

var getModel* = Call_GetModel_603216(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_603217, base: "/",
                                  url: url_GetModel_603218,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_603248 = ref object of OpenApiRestCall_601373
proc url_UpdateModel_603250(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_603249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603251 = path.getOrDefault("model_name")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "model_name", valid_603251
  var valid_603252 = path.getOrDefault("restapi_id")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = nil)
  if valid_603252 != nil:
    section.add "restapi_id", valid_603252
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603253 = header.getOrDefault("X-Amz-Signature")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Signature", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Content-Sha256", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Credential")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Credential", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Security-Token")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Security-Token", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Algorithm")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Algorithm", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-SignedHeaders", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_UpdateModel_603248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603261, url, valid)

proc call*(call_603262: Call_UpdateModel_603248; modelName: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_603263 = newJObject()
  var body_603264 = newJObject()
  add(path_603263, "model_name", newJString(modelName))
  add(path_603263, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603264 = body
  result = call_603262.call(path_603263, nil, nil, nil, body_603264)

var updateModel* = Call_UpdateModel_603248(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_603249,
                                        base: "/", url: url_UpdateModel_603250,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_603233 = ref object of OpenApiRestCall_601373
proc url_DeleteModel_603235(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_603234(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603236 = path.getOrDefault("model_name")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = nil)
  if valid_603236 != nil:
    section.add "model_name", valid_603236
  var valid_603237 = path.getOrDefault("restapi_id")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "restapi_id", valid_603237
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603238 = header.getOrDefault("X-Amz-Signature")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Signature", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Content-Sha256", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Credential")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Credential", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Security-Token")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Security-Token", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Algorithm")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Algorithm", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-SignedHeaders", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603245: Call_DeleteModel_603233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603245, url, valid)

proc call*(call_603246: Call_DeleteModel_603233; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603247 = newJObject()
  add(path_603247, "model_name", newJString(modelName))
  add(path_603247, "restapi_id", newJString(restapiId))
  result = call_603246.call(path_603247, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_603233(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_603234,
                                        base: "/", url: url_DeleteModel_603235,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_603265 = ref object of OpenApiRestCall_601373
proc url_GetRequestValidator_603267(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidator_603266(path: JsonNode; query: JsonNode;
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
  var valid_603268 = path.getOrDefault("restapi_id")
  valid_603268 = validateParameter(valid_603268, JString, required = true,
                                 default = nil)
  if valid_603268 != nil:
    section.add "restapi_id", valid_603268
  var valid_603269 = path.getOrDefault("requestvalidator_id")
  valid_603269 = validateParameter(valid_603269, JString, required = true,
                                 default = nil)
  if valid_603269 != nil:
    section.add "requestvalidator_id", valid_603269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603270 = header.getOrDefault("X-Amz-Signature")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Signature", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Content-Sha256", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Date")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Date", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Credential")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Credential", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Security-Token")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Security-Token", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Algorithm")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Algorithm", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603277: Call_GetRequestValidator_603265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_603277.validator(path, query, header, formData, body)
  let scheme = call_603277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603277.url(scheme.get, call_603277.host, call_603277.base,
                         call_603277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603277, url, valid)

proc call*(call_603278: Call_GetRequestValidator_603265; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  var path_603279 = newJObject()
  add(path_603279, "restapi_id", newJString(restapiId))
  add(path_603279, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_603278.call(path_603279, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_603265(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_603266, base: "/",
    url: url_GetRequestValidator_603267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_603295 = ref object of OpenApiRestCall_601373
proc url_UpdateRequestValidator_603297(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRequestValidator_603296(path: JsonNode; query: JsonNode;
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
  var valid_603298 = path.getOrDefault("restapi_id")
  valid_603298 = validateParameter(valid_603298, JString, required = true,
                                 default = nil)
  if valid_603298 != nil:
    section.add "restapi_id", valid_603298
  var valid_603299 = path.getOrDefault("requestvalidator_id")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "requestvalidator_id", valid_603299
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Signature")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Signature", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Content-Sha256", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Date")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Date", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Credential")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Credential", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Security-Token")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Security-Token", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Algorithm")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Algorithm", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603308: Call_UpdateRequestValidator_603295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_603308.validator(path, query, header, formData, body)
  let scheme = call_603308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603308.url(scheme.get, call_603308.host, call_603308.base,
                         call_603308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603308, url, valid)

proc call*(call_603309: Call_UpdateRequestValidator_603295; restapiId: string;
          requestvalidatorId: string; body: JsonNode): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  var path_603310 = newJObject()
  var body_603311 = newJObject()
  add(path_603310, "restapi_id", newJString(restapiId))
  add(path_603310, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_603311 = body
  result = call_603309.call(path_603310, nil, nil, nil, body_603311)

var updateRequestValidator* = Call_UpdateRequestValidator_603295(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_603296, base: "/",
    url: url_UpdateRequestValidator_603297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_603280 = ref object of OpenApiRestCall_601373
proc url_DeleteRequestValidator_603282(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRequestValidator_603281(path: JsonNode; query: JsonNode;
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
  var valid_603283 = path.getOrDefault("restapi_id")
  valid_603283 = validateParameter(valid_603283, JString, required = true,
                                 default = nil)
  if valid_603283 != nil:
    section.add "restapi_id", valid_603283
  var valid_603284 = path.getOrDefault("requestvalidator_id")
  valid_603284 = validateParameter(valid_603284, JString, required = true,
                                 default = nil)
  if valid_603284 != nil:
    section.add "requestvalidator_id", valid_603284
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603285 = header.getOrDefault("X-Amz-Signature")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Signature", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Content-Sha256", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Date")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Date", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Credential")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Credential", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Security-Token")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Security-Token", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Algorithm")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Algorithm", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603292: Call_DeleteRequestValidator_603280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_603292.validator(path, query, header, formData, body)
  let scheme = call_603292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603292.url(scheme.get, call_603292.host, call_603292.base,
                         call_603292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603292, url, valid)

proc call*(call_603293: Call_DeleteRequestValidator_603280; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  var path_603294 = newJObject()
  add(path_603294, "restapi_id", newJString(restapiId))
  add(path_603294, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_603293.call(path_603294, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_603280(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_603281, base: "/",
    url: url_DeleteRequestValidator_603282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_603312 = ref object of OpenApiRestCall_601373
proc url_GetResource_603314(protocol: Scheme; host: string; base: string;
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

proc validate_GetResource_603313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603315 = path.getOrDefault("restapi_id")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = nil)
  if valid_603315 != nil:
    section.add "restapi_id", valid_603315
  var valid_603316 = path.getOrDefault("resource_id")
  valid_603316 = validateParameter(valid_603316, JString, required = true,
                                 default = nil)
  if valid_603316 != nil:
    section.add "resource_id", valid_603316
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_603317 = query.getOrDefault("embed")
  valid_603317 = validateParameter(valid_603317, JArray, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "embed", valid_603317
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603318 = header.getOrDefault("X-Amz-Signature")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Signature", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Content-Sha256", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Date")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Date", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Credential")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Credential", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Security-Token")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Security-Token", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Algorithm")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Algorithm", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-SignedHeaders", valid_603324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603325: Call_GetResource_603312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603325, url, valid)

proc call*(call_603326: Call_GetResource_603312; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_603327 = newJObject()
  var query_603328 = newJObject()
  add(path_603327, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_603328.add "embed", embed
  add(path_603327, "resource_id", newJString(resourceId))
  result = call_603326.call(path_603327, query_603328, nil, nil, nil)

var getResource* = Call_GetResource_603312(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_603313,
                                        base: "/", url: url_GetResource_603314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_603344 = ref object of OpenApiRestCall_601373
proc url_UpdateResource_603346(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResource_603345(path: JsonNode; query: JsonNode;
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
  var valid_603347 = path.getOrDefault("restapi_id")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = nil)
  if valid_603347 != nil:
    section.add "restapi_id", valid_603347
  var valid_603348 = path.getOrDefault("resource_id")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = nil)
  if valid_603348 != nil:
    section.add "resource_id", valid_603348
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603349 = header.getOrDefault("X-Amz-Signature")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Signature", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Content-Sha256", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Date")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Date", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Security-Token")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Security-Token", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Algorithm")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Algorithm", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-SignedHeaders", valid_603355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603357: Call_UpdateResource_603344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_603357.validator(path, query, header, formData, body)
  let scheme = call_603357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603357.url(scheme.get, call_603357.host, call_603357.base,
                         call_603357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603357, url, valid)

proc call*(call_603358: Call_UpdateResource_603344; restapiId: string;
          body: JsonNode; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_603359 = newJObject()
  var body_603360 = newJObject()
  add(path_603359, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603360 = body
  add(path_603359, "resource_id", newJString(resourceId))
  result = call_603358.call(path_603359, nil, nil, nil, body_603360)

var updateResource* = Call_UpdateResource_603344(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_603345, base: "/", url: url_UpdateResource_603346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_603329 = ref object of OpenApiRestCall_601373
proc url_DeleteResource_603331(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResource_603330(path: JsonNode; query: JsonNode;
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
  var valid_603332 = path.getOrDefault("restapi_id")
  valid_603332 = validateParameter(valid_603332, JString, required = true,
                                 default = nil)
  if valid_603332 != nil:
    section.add "restapi_id", valid_603332
  var valid_603333 = path.getOrDefault("resource_id")
  valid_603333 = validateParameter(valid_603333, JString, required = true,
                                 default = nil)
  if valid_603333 != nil:
    section.add "resource_id", valid_603333
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603334 = header.getOrDefault("X-Amz-Signature")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Signature", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Content-Sha256", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Date")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Date", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Security-Token")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Security-Token", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Algorithm")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Algorithm", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-SignedHeaders", valid_603340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603341: Call_DeleteResource_603329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_603341.validator(path, query, header, formData, body)
  let scheme = call_603341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603341.url(scheme.get, call_603341.host, call_603341.base,
                         call_603341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603341, url, valid)

proc call*(call_603342: Call_DeleteResource_603329; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_603343 = newJObject()
  add(path_603343, "restapi_id", newJString(restapiId))
  add(path_603343, "resource_id", newJString(resourceId))
  result = call_603342.call(path_603343, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_603329(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_603330, base: "/", url: url_DeleteResource_603331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_603375 = ref object of OpenApiRestCall_601373
proc url_PutRestApi_603377(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutRestApi_603376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603378 = path.getOrDefault("restapi_id")
  valid_603378 = validateParameter(valid_603378, JString, required = true,
                                 default = nil)
  if valid_603378 != nil:
    section.add "restapi_id", valid_603378
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
  var valid_603379 = query.getOrDefault("failonwarnings")
  valid_603379 = validateParameter(valid_603379, JBool, required = false, default = nil)
  if valid_603379 != nil:
    section.add "failonwarnings", valid_603379
  var valid_603380 = query.getOrDefault("parameters.2.value")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "parameters.2.value", valid_603380
  var valid_603381 = query.getOrDefault("parameters.1.value")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "parameters.1.value", valid_603381
  var valid_603382 = query.getOrDefault("mode")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = newJString("merge"))
  if valid_603382 != nil:
    section.add "mode", valid_603382
  var valid_603383 = query.getOrDefault("parameters.1.key")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "parameters.1.key", valid_603383
  var valid_603384 = query.getOrDefault("parameters.2.key")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "parameters.2.key", valid_603384
  var valid_603385 = query.getOrDefault("parameters.0.value")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "parameters.0.value", valid_603385
  var valid_603386 = query.getOrDefault("parameters.0.key")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "parameters.0.key", valid_603386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603387 = header.getOrDefault("X-Amz-Signature")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Signature", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Content-Sha256", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Date")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Date", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Credential")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Credential", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-SignedHeaders", valid_603393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603395: Call_PutRestApi_603375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_603395.validator(path, query, header, formData, body)
  let scheme = call_603395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603395.url(scheme.get, call_603395.host, call_603395.base,
                         call_603395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603395, url, valid)

proc call*(call_603396: Call_PutRestApi_603375; restapiId: string; body: JsonNode;
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
  var path_603397 = newJObject()
  var query_603398 = newJObject()
  var body_603399 = newJObject()
  add(query_603398, "failonwarnings", newJBool(failonwarnings))
  add(query_603398, "parameters.2.value", newJString(parameters2Value))
  add(query_603398, "parameters.1.value", newJString(parameters1Value))
  add(query_603398, "mode", newJString(mode))
  add(query_603398, "parameters.1.key", newJString(parameters1Key))
  add(path_603397, "restapi_id", newJString(restapiId))
  add(query_603398, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_603399 = body
  add(query_603398, "parameters.0.value", newJString(parameters0Value))
  add(query_603398, "parameters.0.key", newJString(parameters0Key))
  result = call_603396.call(path_603397, query_603398, nil, nil, body_603399)

var putRestApi* = Call_PutRestApi_603375(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_603376,
                                      base: "/", url: url_PutRestApi_603377,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_603361 = ref object of OpenApiRestCall_601373
proc url_GetRestApi_603363(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRestApi_603362(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603364 = path.getOrDefault("restapi_id")
  valid_603364 = validateParameter(valid_603364, JString, required = true,
                                 default = nil)
  if valid_603364 != nil:
    section.add "restapi_id", valid_603364
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Date")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Date", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Credential")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Credential", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Security-Token")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Security-Token", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Algorithm")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Algorithm", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-SignedHeaders", valid_603371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603372: Call_GetRestApi_603361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_603372.validator(path, query, header, formData, body)
  let scheme = call_603372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603372.url(scheme.get, call_603372.host, call_603372.base,
                         call_603372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603372, url, valid)

proc call*(call_603373: Call_GetRestApi_603361; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603374 = newJObject()
  add(path_603374, "restapi_id", newJString(restapiId))
  result = call_603373.call(path_603374, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_603361(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_603362,
                                      base: "/", url: url_GetRestApi_603363,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_603414 = ref object of OpenApiRestCall_601373
proc url_UpdateRestApi_603416(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRestApi_603415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603417 = path.getOrDefault("restapi_id")
  valid_603417 = validateParameter(valid_603417, JString, required = true,
                                 default = nil)
  if valid_603417 != nil:
    section.add "restapi_id", valid_603417
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603418 = header.getOrDefault("X-Amz-Signature")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Signature", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Content-Sha256", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Credential")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Credential", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Security-Token")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Security-Token", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Algorithm")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Algorithm", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-SignedHeaders", valid_603424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603426: Call_UpdateRestApi_603414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_603426.validator(path, query, header, formData, body)
  let scheme = call_603426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603426.url(scheme.get, call_603426.host, call_603426.base,
                         call_603426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603426, url, valid)

proc call*(call_603427: Call_UpdateRestApi_603414; restapiId: string; body: JsonNode): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_603428 = newJObject()
  var body_603429 = newJObject()
  add(path_603428, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603429 = body
  result = call_603427.call(path_603428, nil, nil, nil, body_603429)

var updateRestApi* = Call_UpdateRestApi_603414(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_603415,
    base: "/", url: url_UpdateRestApi_603416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_603400 = ref object of OpenApiRestCall_601373
proc url_DeleteRestApi_603402(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRestApi_603401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603403 = path.getOrDefault("restapi_id")
  valid_603403 = validateParameter(valid_603403, JString, required = true,
                                 default = nil)
  if valid_603403 != nil:
    section.add "restapi_id", valid_603403
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603404 = header.getOrDefault("X-Amz-Signature")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Signature", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Content-Sha256", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Credential")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Credential", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Security-Token")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Security-Token", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-SignedHeaders", valid_603410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603411: Call_DeleteRestApi_603400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_603411.validator(path, query, header, formData, body)
  let scheme = call_603411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603411.url(scheme.get, call_603411.host, call_603411.base,
                         call_603411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603411, url, valid)

proc call*(call_603412: Call_DeleteRestApi_603400; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603413 = newJObject()
  add(path_603413, "restapi_id", newJString(restapiId))
  result = call_603412.call(path_603413, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_603400(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_603401,
    base: "/", url: url_DeleteRestApi_603402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_603430 = ref object of OpenApiRestCall_601373
proc url_GetStage_603432(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_603431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603433 = path.getOrDefault("restapi_id")
  valid_603433 = validateParameter(valid_603433, JString, required = true,
                                 default = nil)
  if valid_603433 != nil:
    section.add "restapi_id", valid_603433
  var valid_603434 = path.getOrDefault("stage_name")
  valid_603434 = validateParameter(valid_603434, JString, required = true,
                                 default = nil)
  if valid_603434 != nil:
    section.add "stage_name", valid_603434
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603435 = header.getOrDefault("X-Amz-Signature")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Signature", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Content-Sha256", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Date")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Date", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Credential")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Credential", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Security-Token")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Security-Token", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Algorithm")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Algorithm", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603442: Call_GetStage_603430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_603442.validator(path, query, header, formData, body)
  let scheme = call_603442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603442.url(scheme.get, call_603442.host, call_603442.base,
                         call_603442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603442, url, valid)

proc call*(call_603443: Call_GetStage_603430; restapiId: string; stageName: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  var path_603444 = newJObject()
  add(path_603444, "restapi_id", newJString(restapiId))
  add(path_603444, "stage_name", newJString(stageName))
  result = call_603443.call(path_603444, nil, nil, nil, nil)

var getStage* = Call_GetStage_603430(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_603431, base: "/",
                                  url: url_GetStage_603432,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_603460 = ref object of OpenApiRestCall_601373
proc url_UpdateStage_603462(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_603461(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603463 = path.getOrDefault("restapi_id")
  valid_603463 = validateParameter(valid_603463, JString, required = true,
                                 default = nil)
  if valid_603463 != nil:
    section.add "restapi_id", valid_603463
  var valid_603464 = path.getOrDefault("stage_name")
  valid_603464 = validateParameter(valid_603464, JString, required = true,
                                 default = nil)
  if valid_603464 != nil:
    section.add "stage_name", valid_603464
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603465 = header.getOrDefault("X-Amz-Signature")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Signature", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Content-Sha256", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Date")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Date", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Credential")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Credential", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Security-Token")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Security-Token", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Algorithm")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Algorithm", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603473: Call_UpdateStage_603460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_603473.validator(path, query, header, formData, body)
  let scheme = call_603473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603473.url(scheme.get, call_603473.host, call_603473.base,
                         call_603473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603473, url, valid)

proc call*(call_603474: Call_UpdateStage_603460; restapiId: string; body: JsonNode;
          stageName: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  var path_603475 = newJObject()
  var body_603476 = newJObject()
  add(path_603475, "restapi_id", newJString(restapiId))
  if body != nil:
    body_603476 = body
  add(path_603475, "stage_name", newJString(stageName))
  result = call_603474.call(path_603475, nil, nil, nil, body_603476)

var updateStage* = Call_UpdateStage_603460(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_603461,
                                        base: "/", url: url_UpdateStage_603462,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_603445 = ref object of OpenApiRestCall_601373
proc url_DeleteStage_603447(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_603446(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603448 = path.getOrDefault("restapi_id")
  valid_603448 = validateParameter(valid_603448, JString, required = true,
                                 default = nil)
  if valid_603448 != nil:
    section.add "restapi_id", valid_603448
  var valid_603449 = path.getOrDefault("stage_name")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = nil)
  if valid_603449 != nil:
    section.add "stage_name", valid_603449
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603450 = header.getOrDefault("X-Amz-Signature")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Signature", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Content-Sha256", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Date")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Date", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Credential")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Credential", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Security-Token")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Security-Token", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Algorithm")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Algorithm", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603457: Call_DeleteStage_603445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_603457.validator(path, query, header, formData, body)
  let scheme = call_603457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603457.url(scheme.get, call_603457.host, call_603457.base,
                         call_603457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603457, url, valid)

proc call*(call_603458: Call_DeleteStage_603445; restapiId: string; stageName: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  var path_603459 = newJObject()
  add(path_603459, "restapi_id", newJString(restapiId))
  add(path_603459, "stage_name", newJString(stageName))
  result = call_603458.call(path_603459, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_603445(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_603446,
                                        base: "/", url: url_DeleteStage_603447,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_603477 = ref object of OpenApiRestCall_601373
proc url_GetUsagePlan_603479(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlan_603478(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603480 = path.getOrDefault("usageplanId")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = nil)
  if valid_603480 != nil:
    section.add "usageplanId", valid_603480
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603481 = header.getOrDefault("X-Amz-Signature")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Signature", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Content-Sha256", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Date")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Date", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Credential")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Credential", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Security-Token")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Security-Token", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Algorithm")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Algorithm", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-SignedHeaders", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603488: Call_GetUsagePlan_603477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_603488.validator(path, query, header, formData, body)
  let scheme = call_603488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603488.url(scheme.get, call_603488.host, call_603488.base,
                         call_603488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603488, url, valid)

proc call*(call_603489: Call_GetUsagePlan_603477; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_603490 = newJObject()
  add(path_603490, "usageplanId", newJString(usageplanId))
  result = call_603489.call(path_603490, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_603477(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_603478,
    base: "/", url: url_GetUsagePlan_603479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_603505 = ref object of OpenApiRestCall_601373
proc url_UpdateUsagePlan_603507(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsagePlan_603506(path: JsonNode; query: JsonNode;
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
  var valid_603508 = path.getOrDefault("usageplanId")
  valid_603508 = validateParameter(valid_603508, JString, required = true,
                                 default = nil)
  if valid_603508 != nil:
    section.add "usageplanId", valid_603508
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603509 = header.getOrDefault("X-Amz-Signature")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Signature", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Content-Sha256", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Date")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Date", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Credential")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Credential", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Security-Token")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Security-Token", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-SignedHeaders", valid_603515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603517: Call_UpdateUsagePlan_603505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_603517.validator(path, query, header, formData, body)
  let scheme = call_603517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603517.url(scheme.get, call_603517.host, call_603517.base,
                         call_603517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603517, url, valid)

proc call*(call_603518: Call_UpdateUsagePlan_603505; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_603519 = newJObject()
  var body_603520 = newJObject()
  add(path_603519, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_603520 = body
  result = call_603518.call(path_603519, nil, nil, nil, body_603520)

var updateUsagePlan* = Call_UpdateUsagePlan_603505(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_603506,
    base: "/", url: url_UpdateUsagePlan_603507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_603491 = ref object of OpenApiRestCall_601373
proc url_DeleteUsagePlan_603493(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlan_603492(path: JsonNode; query: JsonNode;
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
  var valid_603494 = path.getOrDefault("usageplanId")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = nil)
  if valid_603494 != nil:
    section.add "usageplanId", valid_603494
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603495 = header.getOrDefault("X-Amz-Signature")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Signature", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Content-Sha256", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Date")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Date", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Credential")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Credential", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Security-Token")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Security-Token", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Algorithm")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Algorithm", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603502: Call_DeleteUsagePlan_603491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_603502.validator(path, query, header, formData, body)
  let scheme = call_603502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603502.url(scheme.get, call_603502.host, call_603502.base,
                         call_603502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603502, url, valid)

proc call*(call_603503: Call_DeleteUsagePlan_603491; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_603504 = newJObject()
  add(path_603504, "usageplanId", newJString(usageplanId))
  result = call_603503.call(path_603504, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_603491(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_603492,
    base: "/", url: url_DeleteUsagePlan_603493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_603521 = ref object of OpenApiRestCall_601373
proc url_GetUsagePlanKey_603523(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKey_603522(path: JsonNode; query: JsonNode;
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
  var valid_603524 = path.getOrDefault("usageplanId")
  valid_603524 = validateParameter(valid_603524, JString, required = true,
                                 default = nil)
  if valid_603524 != nil:
    section.add "usageplanId", valid_603524
  var valid_603525 = path.getOrDefault("keyId")
  valid_603525 = validateParameter(valid_603525, JString, required = true,
                                 default = nil)
  if valid_603525 != nil:
    section.add "keyId", valid_603525
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603526 = header.getOrDefault("X-Amz-Signature")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Signature", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Content-Sha256", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Date")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Date", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Credential")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Credential", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Security-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Security-Token", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Algorithm")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Algorithm", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-SignedHeaders", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603533: Call_GetUsagePlanKey_603521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_603533.validator(path, query, header, formData, body)
  let scheme = call_603533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603533.url(scheme.get, call_603533.host, call_603533.base,
                         call_603533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603533, url, valid)

proc call*(call_603534: Call_GetUsagePlanKey_603521; usageplanId: string;
          keyId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_603535 = newJObject()
  add(path_603535, "usageplanId", newJString(usageplanId))
  add(path_603535, "keyId", newJString(keyId))
  result = call_603534.call(path_603535, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_603521(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_603522, base: "/", url: url_GetUsagePlanKey_603523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_603536 = ref object of OpenApiRestCall_601373
proc url_DeleteUsagePlanKey_603538(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlanKey_603537(path: JsonNode; query: JsonNode;
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
  var valid_603539 = path.getOrDefault("usageplanId")
  valid_603539 = validateParameter(valid_603539, JString, required = true,
                                 default = nil)
  if valid_603539 != nil:
    section.add "usageplanId", valid_603539
  var valid_603540 = path.getOrDefault("keyId")
  valid_603540 = validateParameter(valid_603540, JString, required = true,
                                 default = nil)
  if valid_603540 != nil:
    section.add "keyId", valid_603540
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603541 = header.getOrDefault("X-Amz-Signature")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Signature", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Content-Sha256", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Date")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Date", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Credential")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Credential", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Algorithm")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Algorithm", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-SignedHeaders", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603548: Call_DeleteUsagePlanKey_603536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_603548.validator(path, query, header, formData, body)
  let scheme = call_603548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603548.url(scheme.get, call_603548.host, call_603548.base,
                         call_603548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603548, url, valid)

proc call*(call_603549: Call_DeleteUsagePlanKey_603536; usageplanId: string;
          keyId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  var path_603550 = newJObject()
  add(path_603550, "usageplanId", newJString(usageplanId))
  add(path_603550, "keyId", newJString(keyId))
  result = call_603549.call(path_603550, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_603536(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_603537, base: "/",
    url: url_DeleteUsagePlanKey_603538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_603551 = ref object of OpenApiRestCall_601373
proc url_GetVpcLink_603553(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetVpcLink_603552(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603554 = path.getOrDefault("vpclink_id")
  valid_603554 = validateParameter(valid_603554, JString, required = true,
                                 default = nil)
  if valid_603554 != nil:
    section.add "vpclink_id", valid_603554
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603555 = header.getOrDefault("X-Amz-Signature")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Signature", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Content-Sha256", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Date")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Date", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Credential")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Credential", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Security-Token")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Security-Token", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Algorithm")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Algorithm", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_GetVpcLink_603551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603562, url, valid)

proc call*(call_603563: Call_GetVpcLink_603551; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_603564 = newJObject()
  add(path_603564, "vpclink_id", newJString(vpclinkId))
  result = call_603563.call(path_603564, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_603551(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_603552,
                                      base: "/", url: url_GetVpcLink_603553,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_603579 = ref object of OpenApiRestCall_601373
proc url_UpdateVpcLink_603581(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVpcLink_603580(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603582 = path.getOrDefault("vpclink_id")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = nil)
  if valid_603582 != nil:
    section.add "vpclink_id", valid_603582
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603583 = header.getOrDefault("X-Amz-Signature")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Signature", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Content-Sha256", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Date")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Date", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Credential")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Credential", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Security-Token")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Security-Token", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Algorithm")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Algorithm", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603591: Call_UpdateVpcLink_603579; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_603591.validator(path, query, header, formData, body)
  let scheme = call_603591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603591.url(scheme.get, call_603591.host, call_603591.base,
                         call_603591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603591, url, valid)

proc call*(call_603592: Call_UpdateVpcLink_603579; vpclinkId: string; body: JsonNode): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  ##   body: JObject (required)
  var path_603593 = newJObject()
  var body_603594 = newJObject()
  add(path_603593, "vpclink_id", newJString(vpclinkId))
  if body != nil:
    body_603594 = body
  result = call_603592.call(path_603593, nil, nil, nil, body_603594)

var updateVpcLink* = Call_UpdateVpcLink_603579(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_603580,
    base: "/", url: url_UpdateVpcLink_603581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_603565 = ref object of OpenApiRestCall_601373
proc url_DeleteVpcLink_603567(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVpcLink_603566(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603568 = path.getOrDefault("vpclink_id")
  valid_603568 = validateParameter(valid_603568, JString, required = true,
                                 default = nil)
  if valid_603568 != nil:
    section.add "vpclink_id", valid_603568
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603569 = header.getOrDefault("X-Amz-Signature")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Signature", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Content-Sha256", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Date")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Date", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Credential")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Credential", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Security-Token")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Security-Token", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Algorithm")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Algorithm", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-SignedHeaders", valid_603575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603576: Call_DeleteVpcLink_603565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_603576.validator(path, query, header, formData, body)
  let scheme = call_603576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603576.url(scheme.get, call_603576.host, call_603576.base,
                         call_603576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603576, url, valid)

proc call*(call_603577: Call_DeleteVpcLink_603565; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_603578 = newJObject()
  add(path_603578, "vpclink_id", newJString(vpclinkId))
  result = call_603577.call(path_603578, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_603565(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_603566,
    base: "/", url: url_DeleteVpcLink_603567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_603595 = ref object of OpenApiRestCall_601373
proc url_FlushStageAuthorizersCache_603597(protocol: Scheme; host: string;
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

proc validate_FlushStageAuthorizersCache_603596(path: JsonNode; query: JsonNode;
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
  var valid_603598 = path.getOrDefault("restapi_id")
  valid_603598 = validateParameter(valid_603598, JString, required = true,
                                 default = nil)
  if valid_603598 != nil:
    section.add "restapi_id", valid_603598
  var valid_603599 = path.getOrDefault("stage_name")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = nil)
  if valid_603599 != nil:
    section.add "stage_name", valid_603599
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603600 = header.getOrDefault("X-Amz-Signature")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Signature", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Date")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Date", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Credential")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Credential", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Security-Token")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Security-Token", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Algorithm")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Algorithm", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-SignedHeaders", valid_603606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603607: Call_FlushStageAuthorizersCache_603595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_603607.validator(path, query, header, formData, body)
  let scheme = call_603607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603607.url(scheme.get, call_603607.host, call_603607.base,
                         call_603607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603607, url, valid)

proc call*(call_603608: Call_FlushStageAuthorizersCache_603595; restapiId: string;
          stageName: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  var path_603609 = newJObject()
  add(path_603609, "restapi_id", newJString(restapiId))
  add(path_603609, "stage_name", newJString(stageName))
  result = call_603608.call(path_603609, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_603595(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_603596, base: "/",
    url: url_FlushStageAuthorizersCache_603597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_603610 = ref object of OpenApiRestCall_601373
proc url_FlushStageCache_603612(protocol: Scheme; host: string; base: string;
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

proc validate_FlushStageCache_603611(path: JsonNode; query: JsonNode;
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
  var valid_603613 = path.getOrDefault("restapi_id")
  valid_603613 = validateParameter(valid_603613, JString, required = true,
                                 default = nil)
  if valid_603613 != nil:
    section.add "restapi_id", valid_603613
  var valid_603614 = path.getOrDefault("stage_name")
  valid_603614 = validateParameter(valid_603614, JString, required = true,
                                 default = nil)
  if valid_603614 != nil:
    section.add "stage_name", valid_603614
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603615 = header.getOrDefault("X-Amz-Signature")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Signature", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Content-Sha256", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Date")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Date", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Credential")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Credential", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Security-Token")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Security-Token", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Algorithm")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Algorithm", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-SignedHeaders", valid_603621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_FlushStageCache_603610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603622, url, valid)

proc call*(call_603623: Call_FlushStageCache_603610; restapiId: string;
          stageName: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  var path_603624 = newJObject()
  add(path_603624, "restapi_id", newJString(restapiId))
  add(path_603624, "stage_name", newJString(stageName))
  result = call_603623.call(path_603624, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_603610(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_603611, base: "/", url: url_FlushStageCache_603612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_603640 = ref object of OpenApiRestCall_601373
proc url_GenerateClientCertificate_603642(protocol: Scheme; host: string;
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

proc validate_GenerateClientCertificate_603641(path: JsonNode; query: JsonNode;
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
  var valid_603643 = header.getOrDefault("X-Amz-Signature")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Signature", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Content-Sha256", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Date")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Date", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Credential")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Credential", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Security-Token")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Security-Token", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Algorithm")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Algorithm", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-SignedHeaders", valid_603649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603651: Call_GenerateClientCertificate_603640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_603651.validator(path, query, header, formData, body)
  let scheme = call_603651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603651.url(scheme.get, call_603651.host, call_603651.base,
                         call_603651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603651, url, valid)

proc call*(call_603652: Call_GenerateClientCertificate_603640; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_603653 = newJObject()
  if body != nil:
    body_603653 = body
  result = call_603652.call(nil, nil, nil, nil, body_603653)

var generateClientCertificate* = Call_GenerateClientCertificate_603640(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_603641, base: "/",
    url: url_GenerateClientCertificate_603642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_603625 = ref object of OpenApiRestCall_601373
proc url_GetClientCertificates_603627(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificates_603626(path: JsonNode; query: JsonNode;
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
  var valid_603628 = query.getOrDefault("limit")
  valid_603628 = validateParameter(valid_603628, JInt, required = false, default = nil)
  if valid_603628 != nil:
    section.add "limit", valid_603628
  var valid_603629 = query.getOrDefault("position")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "position", valid_603629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603630 = header.getOrDefault("X-Amz-Signature")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Signature", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Content-Sha256", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Date")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Date", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Credential")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Credential", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Security-Token")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Security-Token", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Algorithm")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Algorithm", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603637: Call_GetClientCertificates_603625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_603637.validator(path, query, header, formData, body)
  let scheme = call_603637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603637.url(scheme.get, call_603637.host, call_603637.base,
                         call_603637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603637, url, valid)

proc call*(call_603638: Call_GetClientCertificates_603625; limit: int = 0;
          position: string = ""): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_603639 = newJObject()
  add(query_603639, "limit", newJInt(limit))
  add(query_603639, "position", newJString(position))
  result = call_603638.call(nil, query_603639, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_603625(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_603626, base: "/",
    url: url_GetClientCertificates_603627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_603654 = ref object of OpenApiRestCall_601373
proc url_GetAccount_603656(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_603655(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603657 = header.getOrDefault("X-Amz-Signature")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Signature", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Content-Sha256", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Date")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Date", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Credential")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Credential", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Security-Token")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Security-Token", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Algorithm")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Algorithm", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-SignedHeaders", valid_603663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603664: Call_GetAccount_603654; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_603664.validator(path, query, header, formData, body)
  let scheme = call_603664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603664.url(scheme.get, call_603664.host, call_603664.base,
                         call_603664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603664, url, valid)

proc call*(call_603665: Call_GetAccount_603654): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_603665.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_603654(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_603655,
                                      base: "/", url: url_GetAccount_603656,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_603666 = ref object of OpenApiRestCall_601373
proc url_UpdateAccount_603668(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_603667(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603669 = header.getOrDefault("X-Amz-Signature")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Signature", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Content-Sha256", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Date")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Date", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Credential")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Credential", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Security-Token")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Security-Token", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Algorithm")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Algorithm", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-SignedHeaders", valid_603675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603677: Call_UpdateAccount_603666; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_603677.validator(path, query, header, formData, body)
  let scheme = call_603677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603677.url(scheme.get, call_603677.host, call_603677.base,
                         call_603677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603677, url, valid)

proc call*(call_603678: Call_UpdateAccount_603666; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_603679 = newJObject()
  if body != nil:
    body_603679 = body
  result = call_603678.call(nil, nil, nil, nil, body_603679)

var updateAccount* = Call_UpdateAccount_603666(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_603667, base: "/", url: url_UpdateAccount_603668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_603680 = ref object of OpenApiRestCall_601373
proc url_GetExport_603682(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetExport_603681(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603683 = path.getOrDefault("export_type")
  valid_603683 = validateParameter(valid_603683, JString, required = true,
                                 default = nil)
  if valid_603683 != nil:
    section.add "export_type", valid_603683
  var valid_603684 = path.getOrDefault("restapi_id")
  valid_603684 = validateParameter(valid_603684, JString, required = true,
                                 default = nil)
  if valid_603684 != nil:
    section.add "restapi_id", valid_603684
  var valid_603685 = path.getOrDefault("stage_name")
  valid_603685 = validateParameter(valid_603685, JString, required = true,
                                 default = nil)
  if valid_603685 != nil:
    section.add "stage_name", valid_603685
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_603686 = query.getOrDefault("parameters.2.value")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "parameters.2.value", valid_603686
  var valid_603687 = query.getOrDefault("parameters.1.value")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "parameters.1.value", valid_603687
  var valid_603688 = query.getOrDefault("parameters.1.key")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "parameters.1.key", valid_603688
  var valid_603689 = query.getOrDefault("parameters.2.key")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "parameters.2.key", valid_603689
  var valid_603690 = query.getOrDefault("parameters.0.value")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "parameters.0.value", valid_603690
  var valid_603691 = query.getOrDefault("parameters.0.key")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "parameters.0.key", valid_603691
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
  var valid_603692 = header.getOrDefault("X-Amz-Signature")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Signature", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Content-Sha256", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Date")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Date", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Credential")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Credential", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Security-Token")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Security-Token", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Algorithm")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Algorithm", valid_603697
  var valid_603698 = header.getOrDefault("Accept")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "Accept", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-SignedHeaders", valid_603699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603700: Call_GetExport_603680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_603700.validator(path, query, header, formData, body)
  let scheme = call_603700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603700.url(scheme.get, call_603700.host, call_603700.base,
                         call_603700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603700, url, valid)

proc call*(call_603701: Call_GetExport_603680; exportType: string; restapiId: string;
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
  var path_603702 = newJObject()
  var query_603703 = newJObject()
  add(query_603703, "parameters.2.value", newJString(parameters2Value))
  add(query_603703, "parameters.1.value", newJString(parameters1Value))
  add(query_603703, "parameters.1.key", newJString(parameters1Key))
  add(path_603702, "export_type", newJString(exportType))
  add(path_603702, "restapi_id", newJString(restapiId))
  add(query_603703, "parameters.2.key", newJString(parameters2Key))
  add(path_603702, "stage_name", newJString(stageName))
  add(query_603703, "parameters.0.value", newJString(parameters0Value))
  add(query_603703, "parameters.0.key", newJString(parameters0Key))
  result = call_603701.call(path_603702, query_603703, nil, nil, nil)

var getExport* = Call_GetExport_603680(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_603681,
                                    base: "/", url: url_GetExport_603682,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_603704 = ref object of OpenApiRestCall_601373
proc url_GetGatewayResponses_603706(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponses_603705(path: JsonNode; query: JsonNode;
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
  var valid_603707 = path.getOrDefault("restapi_id")
  valid_603707 = validateParameter(valid_603707, JString, required = true,
                                 default = nil)
  if valid_603707 != nil:
    section.add "restapi_id", valid_603707
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  section = newJObject()
  var valid_603708 = query.getOrDefault("limit")
  valid_603708 = validateParameter(valid_603708, JInt, required = false, default = nil)
  if valid_603708 != nil:
    section.add "limit", valid_603708
  var valid_603709 = query.getOrDefault("position")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "position", valid_603709
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603710 = header.getOrDefault("X-Amz-Signature")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Signature", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Content-Sha256", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Date")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Date", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Credential")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Credential", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Security-Token")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Security-Token", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Algorithm")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Algorithm", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-SignedHeaders", valid_603716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603717: Call_GetGatewayResponses_603704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_603717.validator(path, query, header, formData, body)
  let scheme = call_603717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603717.url(scheme.get, call_603717.host, call_603717.base,
                         call_603717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603717, url, valid)

proc call*(call_603718: Call_GetGatewayResponses_603704; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603719 = newJObject()
  var query_603720 = newJObject()
  add(query_603720, "limit", newJInt(limit))
  add(query_603720, "position", newJString(position))
  add(path_603719, "restapi_id", newJString(restapiId))
  result = call_603718.call(path_603719, query_603720, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_603704(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_603705, base: "/",
    url: url_GetGatewayResponses_603706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_603721 = ref object of OpenApiRestCall_601373
proc url_GetModelTemplate_603723(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_603722(path: JsonNode; query: JsonNode;
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
  var valid_603724 = path.getOrDefault("model_name")
  valid_603724 = validateParameter(valid_603724, JString, required = true,
                                 default = nil)
  if valid_603724 != nil:
    section.add "model_name", valid_603724
  var valid_603725 = path.getOrDefault("restapi_id")
  valid_603725 = validateParameter(valid_603725, JString, required = true,
                                 default = nil)
  if valid_603725 != nil:
    section.add "restapi_id", valid_603725
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603726 = header.getOrDefault("X-Amz-Signature")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Signature", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Content-Sha256", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Date")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Date", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Credential")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Credential", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Security-Token")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Security-Token", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Algorithm")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Algorithm", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-SignedHeaders", valid_603732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603733: Call_GetModelTemplate_603721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_603733.validator(path, query, header, formData, body)
  let scheme = call_603733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603733.url(scheme.get, call_603733.host, call_603733.base,
                         call_603733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603733, url, valid)

proc call*(call_603734: Call_GetModelTemplate_603721; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603735 = newJObject()
  add(path_603735, "model_name", newJString(modelName))
  add(path_603735, "restapi_id", newJString(restapiId))
  result = call_603734.call(path_603735, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_603721(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_603722, base: "/",
    url: url_GetModelTemplate_603723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_603736 = ref object of OpenApiRestCall_601373
proc url_GetResources_603738(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_603737(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603739 = path.getOrDefault("restapi_id")
  valid_603739 = validateParameter(valid_603739, JString, required = true,
                                 default = nil)
  if valid_603739 != nil:
    section.add "restapi_id", valid_603739
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  section = newJObject()
  var valid_603740 = query.getOrDefault("limit")
  valid_603740 = validateParameter(valid_603740, JInt, required = false, default = nil)
  if valid_603740 != nil:
    section.add "limit", valid_603740
  var valid_603741 = query.getOrDefault("position")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "position", valid_603741
  var valid_603742 = query.getOrDefault("embed")
  valid_603742 = validateParameter(valid_603742, JArray, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "embed", valid_603742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603743 = header.getOrDefault("X-Amz-Signature")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Signature", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Content-Sha256", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Date")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Date", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Credential")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Credential", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Security-Token")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Security-Token", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Algorithm")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Algorithm", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-SignedHeaders", valid_603749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603750: Call_GetResources_603736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_603750.validator(path, query, header, formData, body)
  let scheme = call_603750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603750.url(scheme.get, call_603750.host, call_603750.base,
                         call_603750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603750, url, valid)

proc call*(call_603751: Call_GetResources_603736; restapiId: string; limit: int = 0;
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
  var path_603752 = newJObject()
  var query_603753 = newJObject()
  add(query_603753, "limit", newJInt(limit))
  add(query_603753, "position", newJString(position))
  add(path_603752, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_603753.add "embed", embed
  result = call_603751.call(path_603752, query_603753, nil, nil, nil)

var getResources* = Call_GetResources_603736(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_603737,
    base: "/", url: url_GetResources_603738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_603754 = ref object of OpenApiRestCall_601373
proc url_GetSdk_603756(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdk_603755(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603757 = path.getOrDefault("sdk_type")
  valid_603757 = validateParameter(valid_603757, JString, required = true,
                                 default = nil)
  if valid_603757 != nil:
    section.add "sdk_type", valid_603757
  var valid_603758 = path.getOrDefault("restapi_id")
  valid_603758 = validateParameter(valid_603758, JString, required = true,
                                 default = nil)
  if valid_603758 != nil:
    section.add "restapi_id", valid_603758
  var valid_603759 = path.getOrDefault("stage_name")
  valid_603759 = validateParameter(valid_603759, JString, required = true,
                                 default = nil)
  if valid_603759 != nil:
    section.add "stage_name", valid_603759
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_603760 = query.getOrDefault("parameters.2.value")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "parameters.2.value", valid_603760
  var valid_603761 = query.getOrDefault("parameters.1.value")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "parameters.1.value", valid_603761
  var valid_603762 = query.getOrDefault("parameters.1.key")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "parameters.1.key", valid_603762
  var valid_603763 = query.getOrDefault("parameters.2.key")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "parameters.2.key", valid_603763
  var valid_603764 = query.getOrDefault("parameters.0.value")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "parameters.0.value", valid_603764
  var valid_603765 = query.getOrDefault("parameters.0.key")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "parameters.0.key", valid_603765
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603766 = header.getOrDefault("X-Amz-Signature")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Signature", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Content-Sha256", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Date")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Date", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Credential")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Credential", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Security-Token")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Security-Token", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-Algorithm")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Algorithm", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-SignedHeaders", valid_603772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603773: Call_GetSdk_603754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_603773.validator(path, query, header, formData, body)
  let scheme = call_603773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603773.url(scheme.get, call_603773.host, call_603773.base,
                         call_603773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603773, url, valid)

proc call*(call_603774: Call_GetSdk_603754; sdkType: string; restapiId: string;
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
  var path_603775 = newJObject()
  var query_603776 = newJObject()
  add(path_603775, "sdk_type", newJString(sdkType))
  add(query_603776, "parameters.2.value", newJString(parameters2Value))
  add(query_603776, "parameters.1.value", newJString(parameters1Value))
  add(query_603776, "parameters.1.key", newJString(parameters1Key))
  add(path_603775, "restapi_id", newJString(restapiId))
  add(query_603776, "parameters.2.key", newJString(parameters2Key))
  add(path_603775, "stage_name", newJString(stageName))
  add(query_603776, "parameters.0.value", newJString(parameters0Value))
  add(query_603776, "parameters.0.key", newJString(parameters0Key))
  result = call_603774.call(path_603775, query_603776, nil, nil, nil)

var getSdk* = Call_GetSdk_603754(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_603755, base: "/",
                              url: url_GetSdk_603756,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_603777 = ref object of OpenApiRestCall_601373
proc url_GetSdkType_603779(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdkType_603778(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_603780 = path.getOrDefault("sdktype_id")
  valid_603780 = validateParameter(valid_603780, JString, required = true,
                                 default = nil)
  if valid_603780 != nil:
    section.add "sdktype_id", valid_603780
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603781 = header.getOrDefault("X-Amz-Signature")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Signature", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Content-Sha256", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Date")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Date", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Credential")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Credential", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Security-Token")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Security-Token", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Algorithm")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Algorithm", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-SignedHeaders", valid_603787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603788: Call_GetSdkType_603777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603788.validator(path, query, header, formData, body)
  let scheme = call_603788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603788.url(scheme.get, call_603788.host, call_603788.base,
                         call_603788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603788, url, valid)

proc call*(call_603789: Call_GetSdkType_603777; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_603790 = newJObject()
  add(path_603790, "sdktype_id", newJString(sdktypeId))
  result = call_603789.call(path_603790, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_603777(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_603778,
                                      base: "/", url: url_GetSdkType_603779,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_603791 = ref object of OpenApiRestCall_601373
proc url_GetSdkTypes_603793(protocol: Scheme; host: string; base: string;
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

proc validate_GetSdkTypes_603792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603794 = query.getOrDefault("limit")
  valid_603794 = validateParameter(valid_603794, JInt, required = false, default = nil)
  if valid_603794 != nil:
    section.add "limit", valid_603794
  var valid_603795 = query.getOrDefault("position")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "position", valid_603795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603796 = header.getOrDefault("X-Amz-Signature")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Signature", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Content-Sha256", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Date")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Date", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Credential")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Credential", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Security-Token")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Security-Token", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Algorithm")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Algorithm", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-SignedHeaders", valid_603802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603803: Call_GetSdkTypes_603791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603803.validator(path, query, header, formData, body)
  let scheme = call_603803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603803.url(scheme.get, call_603803.host, call_603803.base,
                         call_603803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603803, url, valid)

proc call*(call_603804: Call_GetSdkTypes_603791; limit: int = 0; position: string = ""): Recallable =
  ## getSdkTypes
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_603805 = newJObject()
  add(query_603805, "limit", newJInt(limit))
  add(query_603805, "position", newJString(position))
  result = call_603804.call(nil, query_603805, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_603791(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_603792,
                                        base: "/", url: url_GetSdkTypes_603793,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603823 = ref object of OpenApiRestCall_601373
proc url_TagResource_603825(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603824(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603826 = path.getOrDefault("resource_arn")
  valid_603826 = validateParameter(valid_603826, JString, required = true,
                                 default = nil)
  if valid_603826 != nil:
    section.add "resource_arn", valid_603826
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603827 = header.getOrDefault("X-Amz-Signature")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Signature", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Content-Sha256", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Date")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Date", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Credential")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Credential", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Security-Token")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Security-Token", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Algorithm")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Algorithm", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-SignedHeaders", valid_603833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603835: Call_TagResource_603823; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_603835.validator(path, query, header, formData, body)
  let scheme = call_603835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603835.url(scheme.get, call_603835.host, call_603835.base,
                         call_603835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603835, url, valid)

proc call*(call_603836: Call_TagResource_603823; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_603837 = newJObject()
  var body_603838 = newJObject()
  add(path_603837, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_603838 = body
  result = call_603836.call(path_603837, nil, nil, nil, body_603838)

var tagResource* = Call_TagResource_603823(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_603824,
                                        base: "/", url: url_TagResource_603825,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_603806 = ref object of OpenApiRestCall_601373
proc url_GetTags_603808(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_603807(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603809 = path.getOrDefault("resource_arn")
  valid_603809 = validateParameter(valid_603809, JString, required = true,
                                 default = nil)
  if valid_603809 != nil:
    section.add "resource_arn", valid_603809
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  section = newJObject()
  var valid_603810 = query.getOrDefault("limit")
  valid_603810 = validateParameter(valid_603810, JInt, required = false, default = nil)
  if valid_603810 != nil:
    section.add "limit", valid_603810
  var valid_603811 = query.getOrDefault("position")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "position", valid_603811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603812 = header.getOrDefault("X-Amz-Signature")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Signature", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Content-Sha256", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Date")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Date", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Credential")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Credential", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Security-Token")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Security-Token", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Algorithm")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Algorithm", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-SignedHeaders", valid_603818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603819: Call_GetTags_603806; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_603819.validator(path, query, header, formData, body)
  let scheme = call_603819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603819.url(scheme.get, call_603819.host, call_603819.base,
                         call_603819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603819, url, valid)

proc call*(call_603820: Call_GetTags_603806; resourceArn: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  var path_603821 = newJObject()
  var query_603822 = newJObject()
  add(query_603822, "limit", newJInt(limit))
  add(path_603821, "resource_arn", newJString(resourceArn))
  add(query_603822, "position", newJString(position))
  result = call_603820.call(path_603821, query_603822, nil, nil, nil)

var getTags* = Call_GetTags_603806(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_603807, base: "/",
                                url: url_GetTags_603808,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_603839 = ref object of OpenApiRestCall_601373
proc url_GetUsage_603841(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUsage_603840(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603842 = path.getOrDefault("usageplanId")
  valid_603842 = validateParameter(valid_603842, JString, required = true,
                                 default = nil)
  if valid_603842 != nil:
    section.add "usageplanId", valid_603842
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
  var valid_603843 = query.getOrDefault("limit")
  valid_603843 = validateParameter(valid_603843, JInt, required = false, default = nil)
  if valid_603843 != nil:
    section.add "limit", valid_603843
  assert query != nil, "query argument is necessary due to required `endDate` field"
  var valid_603844 = query.getOrDefault("endDate")
  valid_603844 = validateParameter(valid_603844, JString, required = true,
                                 default = nil)
  if valid_603844 != nil:
    section.add "endDate", valid_603844
  var valid_603845 = query.getOrDefault("position")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "position", valid_603845
  var valid_603846 = query.getOrDefault("keyId")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "keyId", valid_603846
  var valid_603847 = query.getOrDefault("startDate")
  valid_603847 = validateParameter(valid_603847, JString, required = true,
                                 default = nil)
  if valid_603847 != nil:
    section.add "startDate", valid_603847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603848 = header.getOrDefault("X-Amz-Signature")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Signature", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Content-Sha256", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Date")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Date", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Credential")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Credential", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Security-Token")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Security-Token", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Algorithm")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Algorithm", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-SignedHeaders", valid_603854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603855: Call_GetUsage_603839; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_603855.validator(path, query, header, formData, body)
  let scheme = call_603855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603855.url(scheme.get, call_603855.host, call_603855.base,
                         call_603855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603855, url, valid)

proc call*(call_603856: Call_GetUsage_603839; usageplanId: string; endDate: string;
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
  var path_603857 = newJObject()
  var query_603858 = newJObject()
  add(path_603857, "usageplanId", newJString(usageplanId))
  add(query_603858, "limit", newJInt(limit))
  add(query_603858, "endDate", newJString(endDate))
  add(query_603858, "position", newJString(position))
  add(query_603858, "keyId", newJString(keyId))
  add(query_603858, "startDate", newJString(startDate))
  result = call_603856.call(path_603857, query_603858, nil, nil, nil)

var getUsage* = Call_GetUsage_603839(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_603840, base: "/",
                                  url: url_GetUsage_603841,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_603859 = ref object of OpenApiRestCall_601373
proc url_ImportApiKeys_603861(protocol: Scheme; host: string; base: string;
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

proc validate_ImportApiKeys_603860(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603862 = query.getOrDefault("failonwarnings")
  valid_603862 = validateParameter(valid_603862, JBool, required = false, default = nil)
  if valid_603862 != nil:
    section.add "failonwarnings", valid_603862
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_603863 = query.getOrDefault("mode")
  valid_603863 = validateParameter(valid_603863, JString, required = true,
                                 default = newJString("import"))
  if valid_603863 != nil:
    section.add "mode", valid_603863
  var valid_603864 = query.getOrDefault("format")
  valid_603864 = validateParameter(valid_603864, JString, required = true,
                                 default = newJString("csv"))
  if valid_603864 != nil:
    section.add "format", valid_603864
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603865 = header.getOrDefault("X-Amz-Signature")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Signature", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Content-Sha256", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Date")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Date", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Credential")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Credential", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Security-Token")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Security-Token", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Algorithm")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Algorithm", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-SignedHeaders", valid_603871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603873: Call_ImportApiKeys_603859; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_603873.validator(path, query, header, formData, body)
  let scheme = call_603873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603873.url(scheme.get, call_603873.host, call_603873.base,
                         call_603873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603873, url, valid)

proc call*(call_603874: Call_ImportApiKeys_603859; body: JsonNode;
          failonwarnings: bool = false; mode: string = "import"; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   mode: string (required)
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_603875 = newJObject()
  var body_603876 = newJObject()
  add(query_603875, "failonwarnings", newJBool(failonwarnings))
  add(query_603875, "mode", newJString(mode))
  if body != nil:
    body_603876 = body
  add(query_603875, "format", newJString(format))
  result = call_603874.call(nil, query_603875, nil, nil, body_603876)

var importApiKeys* = Call_ImportApiKeys_603859(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_603860,
    base: "/", url: url_ImportApiKeys_603861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_603877 = ref object of OpenApiRestCall_601373
proc url_ImportRestApi_603879(protocol: Scheme; host: string; base: string;
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

proc validate_ImportRestApi_603878(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603880 = query.getOrDefault("failonwarnings")
  valid_603880 = validateParameter(valid_603880, JBool, required = false, default = nil)
  if valid_603880 != nil:
    section.add "failonwarnings", valid_603880
  var valid_603881 = query.getOrDefault("parameters.2.value")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "parameters.2.value", valid_603881
  var valid_603882 = query.getOrDefault("parameters.1.value")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "parameters.1.value", valid_603882
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_603883 = query.getOrDefault("mode")
  valid_603883 = validateParameter(valid_603883, JString, required = true,
                                 default = newJString("import"))
  if valid_603883 != nil:
    section.add "mode", valid_603883
  var valid_603884 = query.getOrDefault("parameters.1.key")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "parameters.1.key", valid_603884
  var valid_603885 = query.getOrDefault("parameters.2.key")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "parameters.2.key", valid_603885
  var valid_603886 = query.getOrDefault("parameters.0.value")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "parameters.0.value", valid_603886
  var valid_603887 = query.getOrDefault("parameters.0.key")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "parameters.0.key", valid_603887
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603888 = header.getOrDefault("X-Amz-Signature")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Signature", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Content-Sha256", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Date")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Date", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Credential")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Credential", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-Security-Token")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Security-Token", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Algorithm")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Algorithm", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-SignedHeaders", valid_603894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603896: Call_ImportRestApi_603877; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_603896.validator(path, query, header, formData, body)
  let scheme = call_603896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603896.url(scheme.get, call_603896.host, call_603896.base,
                         call_603896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603896, url, valid)

proc call*(call_603897: Call_ImportRestApi_603877; body: JsonNode;
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
  var query_603898 = newJObject()
  var body_603899 = newJObject()
  add(query_603898, "failonwarnings", newJBool(failonwarnings))
  add(query_603898, "parameters.2.value", newJString(parameters2Value))
  add(query_603898, "parameters.1.value", newJString(parameters1Value))
  add(query_603898, "mode", newJString(mode))
  add(query_603898, "parameters.1.key", newJString(parameters1Key))
  add(query_603898, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_603899 = body
  add(query_603898, "parameters.0.value", newJString(parameters0Value))
  add(query_603898, "parameters.0.key", newJString(parameters0Key))
  result = call_603897.call(nil, query_603898, nil, nil, body_603899)

var importRestApi* = Call_ImportRestApi_603877(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_603878,
    base: "/", url: url_ImportRestApi_603879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603900 = ref object of OpenApiRestCall_601373
proc url_UntagResource_603902(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603901(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603903 = path.getOrDefault("resource_arn")
  valid_603903 = validateParameter(valid_603903, JString, required = true,
                                 default = nil)
  if valid_603903 != nil:
    section.add "resource_arn", valid_603903
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603904 = query.getOrDefault("tagKeys")
  valid_603904 = validateParameter(valid_603904, JArray, required = true, default = nil)
  if valid_603904 != nil:
    section.add "tagKeys", valid_603904
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603905 = header.getOrDefault("X-Amz-Signature")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Signature", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Content-Sha256", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Date")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Date", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Credential")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Credential", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Security-Token")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Security-Token", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Algorithm")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Algorithm", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-SignedHeaders", valid_603911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603912: Call_UntagResource_603900; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_603912.validator(path, query, header, formData, body)
  let scheme = call_603912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603912.url(scheme.get, call_603912.host, call_603912.base,
                         call_603912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603912, url, valid)

proc call*(call_603913: Call_UntagResource_603900; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_603914 = newJObject()
  var query_603915 = newJObject()
  add(path_603914, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_603915.add "tagKeys", tagKeys
  result = call_603913.call(path_603914, query_603915, nil, nil, nil)

var untagResource* = Call_UntagResource_603900(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_603901,
    base: "/", url: url_UntagResource_603902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_603916 = ref object of OpenApiRestCall_601373
proc url_UpdateUsage_603918(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsage_603917(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603919 = path.getOrDefault("usageplanId")
  valid_603919 = validateParameter(valid_603919, JString, required = true,
                                 default = nil)
  if valid_603919 != nil:
    section.add "usageplanId", valid_603919
  var valid_603920 = path.getOrDefault("keyId")
  valid_603920 = validateParameter(valid_603920, JString, required = true,
                                 default = nil)
  if valid_603920 != nil:
    section.add "keyId", valid_603920
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603921 = header.getOrDefault("X-Amz-Signature")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Signature", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Content-Sha256", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Date")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Date", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Credential")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Credential", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Security-Token")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Security-Token", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Algorithm")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Algorithm", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-SignedHeaders", valid_603927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603929: Call_UpdateUsage_603916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_603929.validator(path, query, header, formData, body)
  let scheme = call_603929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603929.url(scheme.get, call_603929.host, call_603929.base,
                         call_603929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603929, url, valid)

proc call*(call_603930: Call_UpdateUsage_603916; usageplanId: string; keyId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   body: JObject (required)
  var path_603931 = newJObject()
  var body_603932 = newJObject()
  add(path_603931, "usageplanId", newJString(usageplanId))
  add(path_603931, "keyId", newJString(keyId))
  if body != nil:
    body_603932 = body
  result = call_603930.call(path_603931, nil, nil, nil, body_603932)

var updateUsage* = Call_UpdateUsage_603916(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_603917,
                                        base: "/", url: url_UpdateUsage_603918,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
