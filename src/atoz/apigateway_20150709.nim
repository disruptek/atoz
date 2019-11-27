
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  Call_CreateApiKey_599949 = ref object of OpenApiRestCall_599352
proc url_CreateApiKey_599951(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApiKey_599950(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599952 = header.getOrDefault("X-Amz-Date")
  valid_599952 = validateParameter(valid_599952, JString, required = false,
                                 default = nil)
  if valid_599952 != nil:
    section.add "X-Amz-Date", valid_599952
  var valid_599953 = header.getOrDefault("X-Amz-Security-Token")
  valid_599953 = validateParameter(valid_599953, JString, required = false,
                                 default = nil)
  if valid_599953 != nil:
    section.add "X-Amz-Security-Token", valid_599953
  var valid_599954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599954 = validateParameter(valid_599954, JString, required = false,
                                 default = nil)
  if valid_599954 != nil:
    section.add "X-Amz-Content-Sha256", valid_599954
  var valid_599955 = header.getOrDefault("X-Amz-Algorithm")
  valid_599955 = validateParameter(valid_599955, JString, required = false,
                                 default = nil)
  if valid_599955 != nil:
    section.add "X-Amz-Algorithm", valid_599955
  var valid_599956 = header.getOrDefault("X-Amz-Signature")
  valid_599956 = validateParameter(valid_599956, JString, required = false,
                                 default = nil)
  if valid_599956 != nil:
    section.add "X-Amz-Signature", valid_599956
  var valid_599957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599957 = validateParameter(valid_599957, JString, required = false,
                                 default = nil)
  if valid_599957 != nil:
    section.add "X-Amz-SignedHeaders", valid_599957
  var valid_599958 = header.getOrDefault("X-Amz-Credential")
  valid_599958 = validateParameter(valid_599958, JString, required = false,
                                 default = nil)
  if valid_599958 != nil:
    section.add "X-Amz-Credential", valid_599958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599960: Call_CreateApiKey_599949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_599960.validator(path, query, header, formData, body)
  let scheme = call_599960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599960.url(scheme.get, call_599960.host, call_599960.base,
                         call_599960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599960, url, valid)

proc call*(call_599961: Call_CreateApiKey_599949; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_599962 = newJObject()
  if body != nil:
    body_599962 = body
  result = call_599961.call(nil, nil, nil, nil, body_599962)

var createApiKey* = Call_CreateApiKey_599949(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_599950, base: "/", url: url_CreateApiKey_599951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_599689 = ref object of OpenApiRestCall_599352
proc url_GetApiKeys_599691(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApiKeys_599690(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   customerId: JString
  ##             : The identifier of a customer in AWS Marketplace or an external system, such as a developer portal.
  ##   includeValues: JBool
  ##                : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains key values.
  ##   name: JString
  ##       : The name of queried API keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_599803 = query.getOrDefault("customerId")
  valid_599803 = validateParameter(valid_599803, JString, required = false,
                                 default = nil)
  if valid_599803 != nil:
    section.add "customerId", valid_599803
  var valid_599804 = query.getOrDefault("includeValues")
  valid_599804 = validateParameter(valid_599804, JBool, required = false, default = nil)
  if valid_599804 != nil:
    section.add "includeValues", valid_599804
  var valid_599805 = query.getOrDefault("name")
  valid_599805 = validateParameter(valid_599805, JString, required = false,
                                 default = nil)
  if valid_599805 != nil:
    section.add "name", valid_599805
  var valid_599806 = query.getOrDefault("position")
  valid_599806 = validateParameter(valid_599806, JString, required = false,
                                 default = nil)
  if valid_599806 != nil:
    section.add "position", valid_599806
  var valid_599807 = query.getOrDefault("limit")
  valid_599807 = validateParameter(valid_599807, JInt, required = false, default = nil)
  if valid_599807 != nil:
    section.add "limit", valid_599807
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
  var valid_599808 = header.getOrDefault("X-Amz-Date")
  valid_599808 = validateParameter(valid_599808, JString, required = false,
                                 default = nil)
  if valid_599808 != nil:
    section.add "X-Amz-Date", valid_599808
  var valid_599809 = header.getOrDefault("X-Amz-Security-Token")
  valid_599809 = validateParameter(valid_599809, JString, required = false,
                                 default = nil)
  if valid_599809 != nil:
    section.add "X-Amz-Security-Token", valid_599809
  var valid_599810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "X-Amz-Content-Sha256", valid_599810
  var valid_599811 = header.getOrDefault("X-Amz-Algorithm")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "X-Amz-Algorithm", valid_599811
  var valid_599812 = header.getOrDefault("X-Amz-Signature")
  valid_599812 = validateParameter(valid_599812, JString, required = false,
                                 default = nil)
  if valid_599812 != nil:
    section.add "X-Amz-Signature", valid_599812
  var valid_599813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599813 = validateParameter(valid_599813, JString, required = false,
                                 default = nil)
  if valid_599813 != nil:
    section.add "X-Amz-SignedHeaders", valid_599813
  var valid_599814 = header.getOrDefault("X-Amz-Credential")
  valid_599814 = validateParameter(valid_599814, JString, required = false,
                                 default = nil)
  if valid_599814 != nil:
    section.add "X-Amz-Credential", valid_599814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599837: Call_GetApiKeys_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_599837.validator(path, query, header, formData, body)
  let scheme = call_599837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599837.url(scheme.get, call_599837.host, call_599837.base,
                         call_599837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599837, url, valid)

proc call*(call_599908: Call_GetApiKeys_599689; customerId: string = "";
          includeValues: bool = false; name: string = ""; position: string = "";
          limit: int = 0): Recallable =
  ## getApiKeys
  ## Gets information about the current <a>ApiKeys</a> resource.
  ##   customerId: string
  ##             : The identifier of a customer in AWS Marketplace or an external system, such as a developer portal.
  ##   includeValues: bool
  ##                : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains key values.
  ##   name: string
  ##       : The name of queried API keys.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_599909 = newJObject()
  add(query_599909, "customerId", newJString(customerId))
  add(query_599909, "includeValues", newJBool(includeValues))
  add(query_599909, "name", newJString(name))
  add(query_599909, "position", newJString(position))
  add(query_599909, "limit", newJInt(limit))
  result = call_599908.call(nil, query_599909, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_599689(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_599690,
                                      base: "/", url: url_GetApiKeys_599691,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_599994 = ref object of OpenApiRestCall_599352
proc url_CreateAuthorizer_599996(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_599995(path: JsonNode; query: JsonNode;
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
  var valid_599997 = path.getOrDefault("restapi_id")
  valid_599997 = validateParameter(valid_599997, JString, required = true,
                                 default = nil)
  if valid_599997 != nil:
    section.add "restapi_id", valid_599997
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
  var valid_599998 = header.getOrDefault("X-Amz-Date")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Date", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Security-Token")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Security-Token", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Content-Sha256", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Algorithm")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Algorithm", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Signature")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Signature", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-SignedHeaders", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Credential")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Credential", valid_600004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600006: Call_CreateAuthorizer_599994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_600006.validator(path, query, header, formData, body)
  let scheme = call_600006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600006.url(scheme.get, call_600006.host, call_600006.base,
                         call_600006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600006, url, valid)

proc call*(call_600007: Call_CreateAuthorizer_599994; body: JsonNode;
          restapiId: string): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600008 = newJObject()
  var body_600009 = newJObject()
  if body != nil:
    body_600009 = body
  add(path_600008, "restapi_id", newJString(restapiId))
  result = call_600007.call(path_600008, nil, nil, nil, body_600009)

var createAuthorizer* = Call_CreateAuthorizer_599994(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_599995, base: "/",
    url: url_CreateAuthorizer_599996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_599963 = ref object of OpenApiRestCall_599352
proc url_GetAuthorizers_599965(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_599964(path: JsonNode; query: JsonNode;
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
  var valid_599980 = path.getOrDefault("restapi_id")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = nil)
  if valid_599980 != nil:
    section.add "restapi_id", valid_599980
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_599981 = query.getOrDefault("position")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "position", valid_599981
  var valid_599982 = query.getOrDefault("limit")
  valid_599982 = validateParameter(valid_599982, JInt, required = false, default = nil)
  if valid_599982 != nil:
    section.add "limit", valid_599982
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
  var valid_599983 = header.getOrDefault("X-Amz-Date")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Date", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Security-Token")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Security-Token", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Content-Sha256", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Algorithm")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Algorithm", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Signature")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Signature", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-SignedHeaders", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Credential")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Credential", valid_599989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599990: Call_GetAuthorizers_599963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_599990.validator(path, query, header, formData, body)
  let scheme = call_599990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599990.url(scheme.get, call_599990.host, call_599990.base,
                         call_599990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599990, url, valid)

proc call*(call_599991: Call_GetAuthorizers_599963; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_599992 = newJObject()
  var query_599993 = newJObject()
  add(query_599993, "position", newJString(position))
  add(query_599993, "limit", newJInt(limit))
  add(path_599992, "restapi_id", newJString(restapiId))
  result = call_599991.call(path_599992, query_599993, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_599963(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_599964, base: "/", url: url_GetAuthorizers_599965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_600027 = ref object of OpenApiRestCall_599352
proc url_CreateBasePathMapping_600029(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBasePathMapping_600028(path: JsonNode; query: JsonNode;
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
  var valid_600030 = path.getOrDefault("domain_name")
  valid_600030 = validateParameter(valid_600030, JString, required = true,
                                 default = nil)
  if valid_600030 != nil:
    section.add "domain_name", valid_600030
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
  var valid_600031 = header.getOrDefault("X-Amz-Date")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Date", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Security-Token")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Security-Token", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Content-Sha256", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Algorithm")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Algorithm", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Signature")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Signature", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-SignedHeaders", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Credential")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Credential", valid_600037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600039: Call_CreateBasePathMapping_600027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_600039.validator(path, query, header, formData, body)
  let scheme = call_600039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600039.url(scheme.get, call_600039.host, call_600039.base,
                         call_600039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600039, url, valid)

proc call*(call_600040: Call_CreateBasePathMapping_600027; domainName: string;
          body: JsonNode): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  ##   body: JObject (required)
  var path_600041 = newJObject()
  var body_600042 = newJObject()
  add(path_600041, "domain_name", newJString(domainName))
  if body != nil:
    body_600042 = body
  result = call_600040.call(path_600041, nil, nil, nil, body_600042)

var createBasePathMapping* = Call_CreateBasePathMapping_600027(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_600028, base: "/",
    url: url_CreateBasePathMapping_600029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_600010 = ref object of OpenApiRestCall_599352
proc url_GetBasePathMappings_600012(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMappings_600011(path: JsonNode; query: JsonNode;
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
  var valid_600013 = path.getOrDefault("domain_name")
  valid_600013 = validateParameter(valid_600013, JString, required = true,
                                 default = nil)
  if valid_600013 != nil:
    section.add "domain_name", valid_600013
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600014 = query.getOrDefault("position")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "position", valid_600014
  var valid_600015 = query.getOrDefault("limit")
  valid_600015 = validateParameter(valid_600015, JInt, required = false, default = nil)
  if valid_600015 != nil:
    section.add "limit", valid_600015
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
  var valid_600016 = header.getOrDefault("X-Amz-Date")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Date", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Security-Token")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Security-Token", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Content-Sha256", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Algorithm")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Algorithm", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Signature")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Signature", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-SignedHeaders", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Credential")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Credential", valid_600022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600023: Call_GetBasePathMappings_600010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_600023.validator(path, query, header, formData, body)
  let scheme = call_600023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600023.url(scheme.get, call_600023.host, call_600023.base,
                         call_600023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600023, url, valid)

proc call*(call_600024: Call_GetBasePathMappings_600010; domainName: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_600025 = newJObject()
  var query_600026 = newJObject()
  add(path_600025, "domain_name", newJString(domainName))
  add(query_600026, "position", newJString(position))
  add(query_600026, "limit", newJInt(limit))
  result = call_600024.call(path_600025, query_600026, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_600010(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_600011, base: "/",
    url: url_GetBasePathMappings_600012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_600060 = ref object of OpenApiRestCall_599352
proc url_CreateDeployment_600062(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_600061(path: JsonNode; query: JsonNode;
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
  var valid_600063 = path.getOrDefault("restapi_id")
  valid_600063 = validateParameter(valid_600063, JString, required = true,
                                 default = nil)
  if valid_600063 != nil:
    section.add "restapi_id", valid_600063
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
  var valid_600064 = header.getOrDefault("X-Amz-Date")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Date", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Security-Token")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Security-Token", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Content-Sha256", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Algorithm")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Algorithm", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Signature")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Signature", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-SignedHeaders", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Credential")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Credential", valid_600070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600072: Call_CreateDeployment_600060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_600072.validator(path, query, header, formData, body)
  let scheme = call_600072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600072.url(scheme.get, call_600072.host, call_600072.base,
                         call_600072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600072, url, valid)

proc call*(call_600073: Call_CreateDeployment_600060; body: JsonNode;
          restapiId: string): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600074 = newJObject()
  var body_600075 = newJObject()
  if body != nil:
    body_600075 = body
  add(path_600074, "restapi_id", newJString(restapiId))
  result = call_600073.call(path_600074, nil, nil, nil, body_600075)

var createDeployment* = Call_CreateDeployment_600060(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_600061, base: "/",
    url: url_CreateDeployment_600062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_600043 = ref object of OpenApiRestCall_599352
proc url_GetDeployments_600045(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_600044(path: JsonNode; query: JsonNode;
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
  var valid_600046 = path.getOrDefault("restapi_id")
  valid_600046 = validateParameter(valid_600046, JString, required = true,
                                 default = nil)
  if valid_600046 != nil:
    section.add "restapi_id", valid_600046
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600047 = query.getOrDefault("position")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "position", valid_600047
  var valid_600048 = query.getOrDefault("limit")
  valid_600048 = validateParameter(valid_600048, JInt, required = false, default = nil)
  if valid_600048 != nil:
    section.add "limit", valid_600048
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
  var valid_600049 = header.getOrDefault("X-Amz-Date")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Date", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Security-Token")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Security-Token", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Content-Sha256", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Algorithm")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Algorithm", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Signature")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Signature", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-SignedHeaders", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Credential")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Credential", valid_600055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600056: Call_GetDeployments_600043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_600056.validator(path, query, header, formData, body)
  let scheme = call_600056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600056.url(scheme.get, call_600056.host, call_600056.base,
                         call_600056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600056, url, valid)

proc call*(call_600057: Call_GetDeployments_600043; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600058 = newJObject()
  var query_600059 = newJObject()
  add(query_600059, "position", newJString(position))
  add(query_600059, "limit", newJInt(limit))
  add(path_600058, "restapi_id", newJString(restapiId))
  result = call_600057.call(path_600058, query_600059, nil, nil, nil)

var getDeployments* = Call_GetDeployments_600043(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_600044, base: "/", url: url_GetDeployments_600045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_600110 = ref object of OpenApiRestCall_599352
proc url_ImportDocumentationParts_600112(protocol: Scheme; host: string;
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

proc validate_ImportDocumentationParts_600111(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_600113 = path.getOrDefault("restapi_id")
  valid_600113 = validateParameter(valid_600113, JString, required = true,
                                 default = nil)
  if valid_600113 != nil:
    section.add "restapi_id", valid_600113
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  section = newJObject()
  var valid_600114 = query.getOrDefault("mode")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = newJString("merge"))
  if valid_600114 != nil:
    section.add "mode", valid_600114
  var valid_600115 = query.getOrDefault("failonwarnings")
  valid_600115 = validateParameter(valid_600115, JBool, required = false, default = nil)
  if valid_600115 != nil:
    section.add "failonwarnings", valid_600115
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
  var valid_600116 = header.getOrDefault("X-Amz-Date")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Date", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Security-Token")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Security-Token", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Content-Sha256", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Algorithm")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Algorithm", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Signature")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Signature", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-SignedHeaders", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Credential")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Credential", valid_600122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600124: Call_ImportDocumentationParts_600110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600124.validator(path, query, header, formData, body)
  let scheme = call_600124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600124.url(scheme.get, call_600124.host, call_600124.base,
                         call_600124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600124, url, valid)

proc call*(call_600125: Call_ImportDocumentationParts_600110; body: JsonNode;
          restapiId: string; mode: string = "merge"; failonwarnings: bool = false): Recallable =
  ## importDocumentationParts
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600126 = newJObject()
  var query_600127 = newJObject()
  var body_600128 = newJObject()
  add(query_600127, "mode", newJString(mode))
  add(query_600127, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_600128 = body
  add(path_600126, "restapi_id", newJString(restapiId))
  result = call_600125.call(path_600126, query_600127, nil, nil, body_600128)

var importDocumentationParts* = Call_ImportDocumentationParts_600110(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_600111, base: "/",
    url: url_ImportDocumentationParts_600112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_600129 = ref object of OpenApiRestCall_599352
proc url_CreateDocumentationPart_600131(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocumentationPart_600130(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_600132 = path.getOrDefault("restapi_id")
  valid_600132 = validateParameter(valid_600132, JString, required = true,
                                 default = nil)
  if valid_600132 != nil:
    section.add "restapi_id", valid_600132
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
  var valid_600133 = header.getOrDefault("X-Amz-Date")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Date", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Security-Token")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Security-Token", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Content-Sha256", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Algorithm")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Algorithm", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Signature")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Signature", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-SignedHeaders", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Credential")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Credential", valid_600139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600141: Call_CreateDocumentationPart_600129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600141.validator(path, query, header, formData, body)
  let scheme = call_600141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600141.url(scheme.get, call_600141.host, call_600141.base,
                         call_600141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600141, url, valid)

proc call*(call_600142: Call_CreateDocumentationPart_600129; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationPart
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600143 = newJObject()
  var body_600144 = newJObject()
  if body != nil:
    body_600144 = body
  add(path_600143, "restapi_id", newJString(restapiId))
  result = call_600142.call(path_600143, nil, nil, nil, body_600144)

var createDocumentationPart* = Call_CreateDocumentationPart_600129(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_600130, base: "/",
    url: url_CreateDocumentationPart_600131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_600076 = ref object of OpenApiRestCall_599352
proc url_GetDocumentationParts_600078(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationParts_600077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_600079 = path.getOrDefault("restapi_id")
  valid_600079 = validateParameter(valid_600079, JString, required = true,
                                 default = nil)
  if valid_600079 != nil:
    section.add "restapi_id", valid_600079
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The type of API entities of the to-be-retrieved documentation parts. 
  ##   path: JString
  ##       : The path of API entities of the to-be-retrieved documentation parts.
  ##   locationStatus: JString
  ##                 : The status of the API documentation parts to retrieve. Valid values are <code>DOCUMENTED</code> for retrieving <a>DocumentationPart</a> resources with content and <code>UNDOCUMENTED</code> for <a>DocumentationPart</a> resources without content.
  ##   name: JString
  ##       : The name of API entities of the to-be-retrieved documentation parts.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600093 = query.getOrDefault("type")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = newJString("API"))
  if valid_600093 != nil:
    section.add "type", valid_600093
  var valid_600094 = query.getOrDefault("path")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "path", valid_600094
  var valid_600095 = query.getOrDefault("locationStatus")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_600095 != nil:
    section.add "locationStatus", valid_600095
  var valid_600096 = query.getOrDefault("name")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "name", valid_600096
  var valid_600097 = query.getOrDefault("position")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "position", valid_600097
  var valid_600098 = query.getOrDefault("limit")
  valid_600098 = validateParameter(valid_600098, JInt, required = false, default = nil)
  if valid_600098 != nil:
    section.add "limit", valid_600098
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
  var valid_600099 = header.getOrDefault("X-Amz-Date")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Date", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Security-Token")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Security-Token", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Content-Sha256", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Algorithm")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Algorithm", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Signature")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Signature", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-SignedHeaders", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Credential")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Credential", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_GetDocumentationParts_600076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_GetDocumentationParts_600076; restapiId: string;
          `type`: string = "API"; path: string = "";
          locationStatus: string = "DOCUMENTED"; name: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationParts
  ##   type: string
  ##       : The type of API entities of the to-be-retrieved documentation parts. 
  ##   path: string
  ##       : The path of API entities of the to-be-retrieved documentation parts.
  ##   locationStatus: string
  ##                 : The status of the API documentation parts to retrieve. Valid values are <code>DOCUMENTED</code> for retrieving <a>DocumentationPart</a> resources with content and <code>UNDOCUMENTED</code> for <a>DocumentationPart</a> resources without content.
  ##   name: string
  ##       : The name of API entities of the to-be-retrieved documentation parts.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600108 = newJObject()
  var query_600109 = newJObject()
  add(query_600109, "type", newJString(`type`))
  add(query_600109, "path", newJString(path))
  add(query_600109, "locationStatus", newJString(locationStatus))
  add(query_600109, "name", newJString(name))
  add(query_600109, "position", newJString(position))
  add(query_600109, "limit", newJInt(limit))
  add(path_600108, "restapi_id", newJString(restapiId))
  result = call_600107.call(path_600108, query_600109, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_600076(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_600077, base: "/",
    url: url_GetDocumentationParts_600078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_600162 = ref object of OpenApiRestCall_599352
proc url_CreateDocumentationVersion_600164(protocol: Scheme; host: string;
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

proc validate_CreateDocumentationVersion_600163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_600165 = path.getOrDefault("restapi_id")
  valid_600165 = validateParameter(valid_600165, JString, required = true,
                                 default = nil)
  if valid_600165 != nil:
    section.add "restapi_id", valid_600165
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
  var valid_600166 = header.getOrDefault("X-Amz-Date")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Date", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Security-Token")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Security-Token", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Content-Sha256", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Algorithm")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Algorithm", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Signature")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Signature", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-SignedHeaders", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Credential")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Credential", valid_600172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600174: Call_CreateDocumentationVersion_600162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600174.validator(path, query, header, formData, body)
  let scheme = call_600174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600174.url(scheme.get, call_600174.host, call_600174.base,
                         call_600174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600174, url, valid)

proc call*(call_600175: Call_CreateDocumentationVersion_600162; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationVersion
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600176 = newJObject()
  var body_600177 = newJObject()
  if body != nil:
    body_600177 = body
  add(path_600176, "restapi_id", newJString(restapiId))
  result = call_600175.call(path_600176, nil, nil, nil, body_600177)

var createDocumentationVersion* = Call_CreateDocumentationVersion_600162(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_600163, base: "/",
    url: url_CreateDocumentationVersion_600164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_600145 = ref object of OpenApiRestCall_599352
proc url_GetDocumentationVersions_600147(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersions_600146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_600148 = path.getOrDefault("restapi_id")
  valid_600148 = validateParameter(valid_600148, JString, required = true,
                                 default = nil)
  if valid_600148 != nil:
    section.add "restapi_id", valid_600148
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600149 = query.getOrDefault("position")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "position", valid_600149
  var valid_600150 = query.getOrDefault("limit")
  valid_600150 = validateParameter(valid_600150, JInt, required = false, default = nil)
  if valid_600150 != nil:
    section.add "limit", valid_600150
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
  var valid_600151 = header.getOrDefault("X-Amz-Date")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Date", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Security-Token")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Security-Token", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Content-Sha256", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Algorithm")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Algorithm", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Signature")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Signature", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-SignedHeaders", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Credential")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Credential", valid_600157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600158: Call_GetDocumentationVersions_600145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600158.validator(path, query, header, formData, body)
  let scheme = call_600158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600158.url(scheme.get, call_600158.host, call_600158.base,
                         call_600158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600158, url, valid)

proc call*(call_600159: Call_GetDocumentationVersions_600145; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationVersions
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600160 = newJObject()
  var query_600161 = newJObject()
  add(query_600161, "position", newJString(position))
  add(query_600161, "limit", newJInt(limit))
  add(path_600160, "restapi_id", newJString(restapiId))
  result = call_600159.call(path_600160, query_600161, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_600145(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_600146, base: "/",
    url: url_GetDocumentationVersions_600147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_600193 = ref object of OpenApiRestCall_599352
proc url_CreateDomainName_600195(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainName_600194(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600196 = header.getOrDefault("X-Amz-Date")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Date", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Security-Token")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Security-Token", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Content-Sha256", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Algorithm")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Algorithm", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Signature")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Signature", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-SignedHeaders", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Credential")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Credential", valid_600202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600204: Call_CreateDomainName_600193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_600204.validator(path, query, header, formData, body)
  let scheme = call_600204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600204.url(scheme.get, call_600204.host, call_600204.base,
                         call_600204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600204, url, valid)

proc call*(call_600205: Call_CreateDomainName_600193; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_600206 = newJObject()
  if body != nil:
    body_600206 = body
  result = call_600205.call(nil, nil, nil, nil, body_600206)

var createDomainName* = Call_CreateDomainName_600193(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_600194, base: "/",
    url: url_CreateDomainName_600195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_600178 = ref object of OpenApiRestCall_599352
proc url_GetDomainNames_600180(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainNames_600179(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600181 = query.getOrDefault("position")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "position", valid_600181
  var valid_600182 = query.getOrDefault("limit")
  valid_600182 = validateParameter(valid_600182, JInt, required = false, default = nil)
  if valid_600182 != nil:
    section.add "limit", valid_600182
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
  var valid_600183 = header.getOrDefault("X-Amz-Date")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Date", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Security-Token")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Security-Token", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Content-Sha256", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Algorithm")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Algorithm", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Signature")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Signature", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-SignedHeaders", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Credential")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Credential", valid_600189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600190: Call_GetDomainNames_600178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_600190.validator(path, query, header, formData, body)
  let scheme = call_600190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600190.url(scheme.get, call_600190.host, call_600190.base,
                         call_600190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600190, url, valid)

proc call*(call_600191: Call_GetDomainNames_600178; position: string = "";
          limit: int = 0): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_600192 = newJObject()
  add(query_600192, "position", newJString(position))
  add(query_600192, "limit", newJInt(limit))
  result = call_600191.call(nil, query_600192, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_600178(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_600179, base: "/",
    url: url_GetDomainNames_600180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_600224 = ref object of OpenApiRestCall_599352
proc url_CreateModel_600226(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_600225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600227 = path.getOrDefault("restapi_id")
  valid_600227 = validateParameter(valid_600227, JString, required = true,
                                 default = nil)
  if valid_600227 != nil:
    section.add "restapi_id", valid_600227
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
  var valid_600228 = header.getOrDefault("X-Amz-Date")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Date", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Security-Token")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Security-Token", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Content-Sha256", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Algorithm")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Algorithm", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Signature")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Signature", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-SignedHeaders", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Credential")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Credential", valid_600234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600236: Call_CreateModel_600224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_600236.validator(path, query, header, formData, body)
  let scheme = call_600236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600236.url(scheme.get, call_600236.host, call_600236.base,
                         call_600236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600236, url, valid)

proc call*(call_600237: Call_CreateModel_600224; body: JsonNode; restapiId: string): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  var path_600238 = newJObject()
  var body_600239 = newJObject()
  if body != nil:
    body_600239 = body
  add(path_600238, "restapi_id", newJString(restapiId))
  result = call_600237.call(path_600238, nil, nil, nil, body_600239)

var createModel* = Call_CreateModel_600224(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_600225,
                                        base: "/", url: url_CreateModel_600226,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_600207 = ref object of OpenApiRestCall_599352
proc url_GetModels_600209(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_600208(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600210 = path.getOrDefault("restapi_id")
  valid_600210 = validateParameter(valid_600210, JString, required = true,
                                 default = nil)
  if valid_600210 != nil:
    section.add "restapi_id", valid_600210
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600211 = query.getOrDefault("position")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "position", valid_600211
  var valid_600212 = query.getOrDefault("limit")
  valid_600212 = validateParameter(valid_600212, JInt, required = false, default = nil)
  if valid_600212 != nil:
    section.add "limit", valid_600212
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
  var valid_600213 = header.getOrDefault("X-Amz-Date")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Date", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Security-Token")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Security-Token", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Content-Sha256", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Algorithm")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Algorithm", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Signature")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Signature", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-SignedHeaders", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Credential")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Credential", valid_600219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600220: Call_GetModels_600207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_600220.validator(path, query, header, formData, body)
  let scheme = call_600220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600220.url(scheme.get, call_600220.host, call_600220.base,
                         call_600220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600220, url, valid)

proc call*(call_600221: Call_GetModels_600207; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600222 = newJObject()
  var query_600223 = newJObject()
  add(query_600223, "position", newJString(position))
  add(query_600223, "limit", newJInt(limit))
  add(path_600222, "restapi_id", newJString(restapiId))
  result = call_600221.call(path_600222, query_600223, nil, nil, nil)

var getModels* = Call_GetModels_600207(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_600208,
                                    base: "/", url: url_GetModels_600209,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_600257 = ref object of OpenApiRestCall_599352
proc url_CreateRequestValidator_600259(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRequestValidator_600258(path: JsonNode; query: JsonNode;
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
  var valid_600260 = path.getOrDefault("restapi_id")
  valid_600260 = validateParameter(valid_600260, JString, required = true,
                                 default = nil)
  if valid_600260 != nil:
    section.add "restapi_id", valid_600260
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
  var valid_600261 = header.getOrDefault("X-Amz-Date")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Date", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Security-Token")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Security-Token", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Content-Sha256", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Algorithm")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Algorithm", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Signature")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Signature", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-SignedHeaders", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Credential")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Credential", valid_600267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_CreateRequestValidator_600257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_CreateRequestValidator_600257; body: JsonNode;
          restapiId: string): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600271 = newJObject()
  var body_600272 = newJObject()
  if body != nil:
    body_600272 = body
  add(path_600271, "restapi_id", newJString(restapiId))
  result = call_600270.call(path_600271, nil, nil, nil, body_600272)

var createRequestValidator* = Call_CreateRequestValidator_600257(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_600258, base: "/",
    url: url_CreateRequestValidator_600259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_600240 = ref object of OpenApiRestCall_599352
proc url_GetRequestValidators_600242(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidators_600241(path: JsonNode; query: JsonNode;
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
  var valid_600243 = path.getOrDefault("restapi_id")
  valid_600243 = validateParameter(valid_600243, JString, required = true,
                                 default = nil)
  if valid_600243 != nil:
    section.add "restapi_id", valid_600243
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600244 = query.getOrDefault("position")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "position", valid_600244
  var valid_600245 = query.getOrDefault("limit")
  valid_600245 = validateParameter(valid_600245, JInt, required = false, default = nil)
  if valid_600245 != nil:
    section.add "limit", valid_600245
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
  var valid_600246 = header.getOrDefault("X-Amz-Date")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Date", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Security-Token")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Security-Token", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Content-Sha256", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Algorithm")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Algorithm", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Signature")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Signature", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-SignedHeaders", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Credential")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Credential", valid_600252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600253: Call_GetRequestValidators_600240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_600253.validator(path, query, header, formData, body)
  let scheme = call_600253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600253.url(scheme.get, call_600253.host, call_600253.base,
                         call_600253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600253, url, valid)

proc call*(call_600254: Call_GetRequestValidators_600240; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600255 = newJObject()
  var query_600256 = newJObject()
  add(query_600256, "position", newJString(position))
  add(query_600256, "limit", newJInt(limit))
  add(path_600255, "restapi_id", newJString(restapiId))
  result = call_600254.call(path_600255, query_600256, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_600240(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_600241, base: "/",
    url: url_GetRequestValidators_600242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_600273 = ref object of OpenApiRestCall_599352
proc url_CreateResource_600275(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResource_600274(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a <a>Resource</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   parent_id: JString (required)
  ##            : [Required] The parent resource's identifier.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `parent_id` field"
  var valid_600276 = path.getOrDefault("parent_id")
  valid_600276 = validateParameter(valid_600276, JString, required = true,
                                 default = nil)
  if valid_600276 != nil:
    section.add "parent_id", valid_600276
  var valid_600277 = path.getOrDefault("restapi_id")
  valid_600277 = validateParameter(valid_600277, JString, required = true,
                                 default = nil)
  if valid_600277 != nil:
    section.add "restapi_id", valid_600277
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
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_CreateResource_600273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_CreateResource_600273; parentId: string; body: JsonNode;
          restapiId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600288 = newJObject()
  var body_600289 = newJObject()
  add(path_600288, "parent_id", newJString(parentId))
  if body != nil:
    body_600289 = body
  add(path_600288, "restapi_id", newJString(restapiId))
  result = call_600287.call(path_600288, nil, nil, nil, body_600289)

var createResource* = Call_CreateResource_600273(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_600274, base: "/", url: url_CreateResource_600275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_600305 = ref object of OpenApiRestCall_599352
proc url_CreateRestApi_600307(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRestApi_600306(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600308 = header.getOrDefault("X-Amz-Date")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Date", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Security-Token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Security-Token", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_CreateRestApi_600305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_CreateRestApi_600305; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_600318 = newJObject()
  if body != nil:
    body_600318 = body
  result = call_600317.call(nil, nil, nil, nil, body_600318)

var createRestApi* = Call_CreateRestApi_600305(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_600306, base: "/", url: url_CreateRestApi_600307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_600290 = ref object of OpenApiRestCall_599352
proc url_GetRestApis_600292(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestApis_600291(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600293 = query.getOrDefault("position")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "position", valid_600293
  var valid_600294 = query.getOrDefault("limit")
  valid_600294 = validateParameter(valid_600294, JInt, required = false, default = nil)
  if valid_600294 != nil:
    section.add "limit", valid_600294
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
  var valid_600295 = header.getOrDefault("X-Amz-Date")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Date", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Security-Token")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Security-Token", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Content-Sha256", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Algorithm")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Algorithm", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Signature")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Signature", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-SignedHeaders", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Credential")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Credential", valid_600301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600302: Call_GetRestApis_600290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_600302.validator(path, query, header, formData, body)
  let scheme = call_600302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600302.url(scheme.get, call_600302.host, call_600302.base,
                         call_600302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600302, url, valid)

proc call*(call_600303: Call_GetRestApis_600290; position: string = ""; limit: int = 0): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_600304 = newJObject()
  add(query_600304, "position", newJString(position))
  add(query_600304, "limit", newJInt(limit))
  result = call_600303.call(nil, query_600304, nil, nil, nil)

var getRestApis* = Call_GetRestApis_600290(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_600291,
                                        base: "/", url: url_GetRestApis_600292,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_600335 = ref object of OpenApiRestCall_599352
proc url_CreateStage_600337(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_600336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600338 = path.getOrDefault("restapi_id")
  valid_600338 = validateParameter(valid_600338, JString, required = true,
                                 default = nil)
  if valid_600338 != nil:
    section.add "restapi_id", valid_600338
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
  var valid_600339 = header.getOrDefault("X-Amz-Date")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Date", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Security-Token")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Security-Token", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Content-Sha256", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Algorithm")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Algorithm", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Signature")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Signature", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-SignedHeaders", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Credential")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Credential", valid_600345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600347: Call_CreateStage_600335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_600347.validator(path, query, header, formData, body)
  let scheme = call_600347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600347.url(scheme.get, call_600347.host, call_600347.base,
                         call_600347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600347, url, valid)

proc call*(call_600348: Call_CreateStage_600335; body: JsonNode; restapiId: string): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600349 = newJObject()
  var body_600350 = newJObject()
  if body != nil:
    body_600350 = body
  add(path_600349, "restapi_id", newJString(restapiId))
  result = call_600348.call(path_600349, nil, nil, nil, body_600350)

var createStage* = Call_CreateStage_600335(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_600336,
                                        base: "/", url: url_CreateStage_600337,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_600319 = ref object of OpenApiRestCall_599352
proc url_GetStages_600321(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_600320(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600322 = path.getOrDefault("restapi_id")
  valid_600322 = validateParameter(valid_600322, JString, required = true,
                                 default = nil)
  if valid_600322 != nil:
    section.add "restapi_id", valid_600322
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_600323 = query.getOrDefault("deploymentId")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "deploymentId", valid_600323
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
  var valid_600324 = header.getOrDefault("X-Amz-Date")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Date", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Security-Token")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Security-Token", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Content-Sha256", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Algorithm")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Algorithm", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Signature")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Signature", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-SignedHeaders", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Credential")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Credential", valid_600330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600331: Call_GetStages_600319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_600331.validator(path, query, header, formData, body)
  let scheme = call_600331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600331.url(scheme.get, call_600331.host, call_600331.base,
                         call_600331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600331, url, valid)

proc call*(call_600332: Call_GetStages_600319; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600333 = newJObject()
  var query_600334 = newJObject()
  add(query_600334, "deploymentId", newJString(deploymentId))
  add(path_600333, "restapi_id", newJString(restapiId))
  result = call_600332.call(path_600333, query_600334, nil, nil, nil)

var getStages* = Call_GetStages_600319(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_600320,
                                    base: "/", url: url_GetStages_600321,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_600367 = ref object of OpenApiRestCall_599352
proc url_CreateUsagePlan_600369(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUsagePlan_600368(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600370 = header.getOrDefault("X-Amz-Date")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Date", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Security-Token")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Security-Token", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Content-Sha256", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Algorithm")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Algorithm", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Signature")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Signature", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-SignedHeaders", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Credential")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Credential", valid_600376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600378: Call_CreateUsagePlan_600367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_600378.validator(path, query, header, formData, body)
  let scheme = call_600378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600378.url(scheme.get, call_600378.host, call_600378.base,
                         call_600378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600378, url, valid)

proc call*(call_600379: Call_CreateUsagePlan_600367; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_600380 = newJObject()
  if body != nil:
    body_600380 = body
  result = call_600379.call(nil, nil, nil, nil, body_600380)

var createUsagePlan* = Call_CreateUsagePlan_600367(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_600368, base: "/",
    url: url_CreateUsagePlan_600369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_600351 = ref object of OpenApiRestCall_599352
proc url_GetUsagePlans_600353(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUsagePlans_600352(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the usage plans of the caller's account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   keyId: JString
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600354 = query.getOrDefault("keyId")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "keyId", valid_600354
  var valid_600355 = query.getOrDefault("position")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "position", valid_600355
  var valid_600356 = query.getOrDefault("limit")
  valid_600356 = validateParameter(valid_600356, JInt, required = false, default = nil)
  if valid_600356 != nil:
    section.add "limit", valid_600356
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
  var valid_600357 = header.getOrDefault("X-Amz-Date")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Date", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Security-Token")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Security-Token", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Content-Sha256", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Algorithm")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Algorithm", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Signature")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Signature", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-SignedHeaders", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Credential")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Credential", valid_600363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600364: Call_GetUsagePlans_600351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_600364.validator(path, query, header, formData, body)
  let scheme = call_600364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600364.url(scheme.get, call_600364.host, call_600364.base,
                         call_600364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600364, url, valid)

proc call*(call_600365: Call_GetUsagePlans_600351; keyId: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_600366 = newJObject()
  add(query_600366, "keyId", newJString(keyId))
  add(query_600366, "position", newJString(position))
  add(query_600366, "limit", newJInt(limit))
  result = call_600365.call(nil, query_600366, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_600351(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_600352, base: "/",
    url: url_GetUsagePlans_600353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_600399 = ref object of OpenApiRestCall_599352
proc url_CreateUsagePlanKey_600401(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlanKey_600400(path: JsonNode; query: JsonNode;
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
  var valid_600402 = path.getOrDefault("usageplanId")
  valid_600402 = validateParameter(valid_600402, JString, required = true,
                                 default = nil)
  if valid_600402 != nil:
    section.add "usageplanId", valid_600402
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
  var valid_600403 = header.getOrDefault("X-Amz-Date")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Date", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Security-Token")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Security-Token", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Content-Sha256", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Algorithm")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Algorithm", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Signature")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Signature", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-SignedHeaders", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Credential")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Credential", valid_600409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600411: Call_CreateUsagePlanKey_600399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_600411.validator(path, query, header, formData, body)
  let scheme = call_600411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600411.url(scheme.get, call_600411.host, call_600411.base,
                         call_600411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600411, url, valid)

proc call*(call_600412: Call_CreateUsagePlanKey_600399; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_600413 = newJObject()
  var body_600414 = newJObject()
  add(path_600413, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_600414 = body
  result = call_600412.call(path_600413, nil, nil, nil, body_600414)

var createUsagePlanKey* = Call_CreateUsagePlanKey_600399(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_600400, base: "/",
    url: url_CreateUsagePlanKey_600401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_600381 = ref object of OpenApiRestCall_599352
proc url_GetUsagePlanKeys_600383(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKeys_600382(path: JsonNode; query: JsonNode;
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
  var valid_600384 = path.getOrDefault("usageplanId")
  valid_600384 = validateParameter(valid_600384, JString, required = true,
                                 default = nil)
  if valid_600384 != nil:
    section.add "usageplanId", valid_600384
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600385 = query.getOrDefault("name")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "name", valid_600385
  var valid_600386 = query.getOrDefault("position")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "position", valid_600386
  var valid_600387 = query.getOrDefault("limit")
  valid_600387 = validateParameter(valid_600387, JInt, required = false, default = nil)
  if valid_600387 != nil:
    section.add "limit", valid_600387
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
  var valid_600388 = header.getOrDefault("X-Amz-Date")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Date", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Security-Token")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Security-Token", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Content-Sha256", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Algorithm")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Algorithm", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Signature")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Signature", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-SignedHeaders", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Credential")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Credential", valid_600394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600395: Call_GetUsagePlanKeys_600381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_600395.validator(path, query, header, formData, body)
  let scheme = call_600395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600395.url(scheme.get, call_600395.host, call_600395.base,
                         call_600395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600395, url, valid)

proc call*(call_600396: Call_GetUsagePlanKeys_600381; usageplanId: string;
          name: string = ""; position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlanKeys
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   name: string
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_600397 = newJObject()
  var query_600398 = newJObject()
  add(path_600397, "usageplanId", newJString(usageplanId))
  add(query_600398, "name", newJString(name))
  add(query_600398, "position", newJString(position))
  add(query_600398, "limit", newJInt(limit))
  result = call_600396.call(path_600397, query_600398, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_600381(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_600382,
    base: "/", url: url_GetUsagePlanKeys_600383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_600430 = ref object of OpenApiRestCall_599352
proc url_CreateVpcLink_600432(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVpcLink_600431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600433 = header.getOrDefault("X-Amz-Date")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Date", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Security-Token")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Security-Token", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Content-Sha256", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Algorithm")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Algorithm", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Signature")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Signature", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-SignedHeaders", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Credential")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Credential", valid_600439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600441: Call_CreateVpcLink_600430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_600441.validator(path, query, header, formData, body)
  let scheme = call_600441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600441.url(scheme.get, call_600441.host, call_600441.base,
                         call_600441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600441, url, valid)

proc call*(call_600442: Call_CreateVpcLink_600430; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_600443 = newJObject()
  if body != nil:
    body_600443 = body
  result = call_600442.call(nil, nil, nil, nil, body_600443)

var createVpcLink* = Call_CreateVpcLink_600430(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_600431, base: "/", url: url_CreateVpcLink_600432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_600415 = ref object of OpenApiRestCall_599352
proc url_GetVpcLinks_600417(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVpcLinks_600416(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_600418 = query.getOrDefault("position")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "position", valid_600418
  var valid_600419 = query.getOrDefault("limit")
  valid_600419 = validateParameter(valid_600419, JInt, required = false, default = nil)
  if valid_600419 != nil:
    section.add "limit", valid_600419
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
  var valid_600420 = header.getOrDefault("X-Amz-Date")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Date", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Security-Token")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Security-Token", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Content-Sha256", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Algorithm")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Algorithm", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-Signature")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-Signature", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-SignedHeaders", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-Credential")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Credential", valid_600426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600427: Call_GetVpcLinks_600415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_600427.validator(path, query, header, formData, body)
  let scheme = call_600427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600427.url(scheme.get, call_600427.host, call_600427.base,
                         call_600427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600427, url, valid)

proc call*(call_600428: Call_GetVpcLinks_600415; position: string = ""; limit: int = 0): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_600429 = newJObject()
  add(query_600429, "position", newJString(position))
  add(query_600429, "limit", newJInt(limit))
  result = call_600428.call(nil, query_600429, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_600415(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_600416,
                                        base: "/", url: url_GetVpcLinks_600417,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_600444 = ref object of OpenApiRestCall_599352
proc url_GetApiKey_600446(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKey_600445(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600447 = path.getOrDefault("api_Key")
  valid_600447 = validateParameter(valid_600447, JString, required = true,
                                 default = nil)
  if valid_600447 != nil:
    section.add "api_Key", valid_600447
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_600448 = query.getOrDefault("includeValue")
  valid_600448 = validateParameter(valid_600448, JBool, required = false, default = nil)
  if valid_600448 != nil:
    section.add "includeValue", valid_600448
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
  var valid_600449 = header.getOrDefault("X-Amz-Date")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Date", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Security-Token")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Security-Token", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Content-Sha256", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Algorithm")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Algorithm", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Signature")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Signature", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-SignedHeaders", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Credential")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Credential", valid_600455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600456: Call_GetApiKey_600444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_600456.validator(path, query, header, formData, body)
  let scheme = call_600456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600456.url(scheme.get, call_600456.host, call_600456.base,
                         call_600456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600456, url, valid)

proc call*(call_600457: Call_GetApiKey_600444; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_600458 = newJObject()
  var query_600459 = newJObject()
  add(query_600459, "includeValue", newJBool(includeValue))
  add(path_600458, "api_Key", newJString(apiKey))
  result = call_600457.call(path_600458, query_600459, nil, nil, nil)

var getApiKey* = Call_GetApiKey_600444(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_600445,
                                    base: "/", url: url_GetApiKey_600446,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_600474 = ref object of OpenApiRestCall_599352
proc url_UpdateApiKey_600476(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_600475(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600477 = path.getOrDefault("api_Key")
  valid_600477 = validateParameter(valid_600477, JString, required = true,
                                 default = nil)
  if valid_600477 != nil:
    section.add "api_Key", valid_600477
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
  var valid_600478 = header.getOrDefault("X-Amz-Date")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Date", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Security-Token")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Security-Token", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Content-Sha256", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Algorithm")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Algorithm", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Signature")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Signature", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-SignedHeaders", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Credential")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Credential", valid_600484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600486: Call_UpdateApiKey_600474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_600486.validator(path, query, header, formData, body)
  let scheme = call_600486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600486.url(scheme.get, call_600486.host, call_600486.base,
                         call_600486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600486, url, valid)

proc call*(call_600487: Call_UpdateApiKey_600474; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_600488 = newJObject()
  var body_600489 = newJObject()
  add(path_600488, "api_Key", newJString(apiKey))
  if body != nil:
    body_600489 = body
  result = call_600487.call(path_600488, nil, nil, nil, body_600489)

var updateApiKey* = Call_UpdateApiKey_600474(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_600475, base: "/",
    url: url_UpdateApiKey_600476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_600460 = ref object of OpenApiRestCall_599352
proc url_DeleteApiKey_600462(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_600461(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600463 = path.getOrDefault("api_Key")
  valid_600463 = validateParameter(valid_600463, JString, required = true,
                                 default = nil)
  if valid_600463 != nil:
    section.add "api_Key", valid_600463
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
  var valid_600464 = header.getOrDefault("X-Amz-Date")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Date", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Security-Token")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Security-Token", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Content-Sha256", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Algorithm")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Algorithm", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Signature")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Signature", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-SignedHeaders", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Credential")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Credential", valid_600470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600471: Call_DeleteApiKey_600460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_600471.validator(path, query, header, formData, body)
  let scheme = call_600471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600471.url(scheme.get, call_600471.host, call_600471.base,
                         call_600471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600471, url, valid)

proc call*(call_600472: Call_DeleteApiKey_600460; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_600473 = newJObject()
  add(path_600473, "api_Key", newJString(apiKey))
  result = call_600472.call(path_600473, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_600460(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_600461, base: "/",
    url: url_DeleteApiKey_600462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_600505 = ref object of OpenApiRestCall_599352
proc url_TestInvokeAuthorizer_600507(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeAuthorizer_600506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   authorizer_id: JString (required)
  ##                : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `authorizer_id` field"
  var valid_600508 = path.getOrDefault("authorizer_id")
  valid_600508 = validateParameter(valid_600508, JString, required = true,
                                 default = nil)
  if valid_600508 != nil:
    section.add "authorizer_id", valid_600508
  var valid_600509 = path.getOrDefault("restapi_id")
  valid_600509 = validateParameter(valid_600509, JString, required = true,
                                 default = nil)
  if valid_600509 != nil:
    section.add "restapi_id", valid_600509
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
  var valid_600510 = header.getOrDefault("X-Amz-Date")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Date", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Security-Token")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Security-Token", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-Content-Sha256", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Algorithm")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Algorithm", valid_600513
  var valid_600514 = header.getOrDefault("X-Amz-Signature")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "X-Amz-Signature", valid_600514
  var valid_600515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-SignedHeaders", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Credential")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Credential", valid_600516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600518: Call_TestInvokeAuthorizer_600505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_600518.validator(path, query, header, formData, body)
  let scheme = call_600518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600518.url(scheme.get, call_600518.host, call_600518.base,
                         call_600518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600518, url, valid)

proc call*(call_600519: Call_TestInvokeAuthorizer_600505; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600520 = newJObject()
  var body_600521 = newJObject()
  add(path_600520, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_600521 = body
  add(path_600520, "restapi_id", newJString(restapiId))
  result = call_600519.call(path_600520, nil, nil, nil, body_600521)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_600505(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_600506, base: "/",
    url: url_TestInvokeAuthorizer_600507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_600490 = ref object of OpenApiRestCall_599352
proc url_GetAuthorizer_600492(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_600491(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   authorizer_id: JString (required)
  ##                : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `authorizer_id` field"
  var valid_600493 = path.getOrDefault("authorizer_id")
  valid_600493 = validateParameter(valid_600493, JString, required = true,
                                 default = nil)
  if valid_600493 != nil:
    section.add "authorizer_id", valid_600493
  var valid_600494 = path.getOrDefault("restapi_id")
  valid_600494 = validateParameter(valid_600494, JString, required = true,
                                 default = nil)
  if valid_600494 != nil:
    section.add "restapi_id", valid_600494
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
  var valid_600495 = header.getOrDefault("X-Amz-Date")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Date", valid_600495
  var valid_600496 = header.getOrDefault("X-Amz-Security-Token")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Security-Token", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Content-Sha256", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Algorithm")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Algorithm", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Signature")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Signature", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-SignedHeaders", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Credential")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Credential", valid_600501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600502: Call_GetAuthorizer_600490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_600502.validator(path, query, header, formData, body)
  let scheme = call_600502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600502.url(scheme.get, call_600502.host, call_600502.base,
                         call_600502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600502, url, valid)

proc call*(call_600503: Call_GetAuthorizer_600490; authorizerId: string;
          restapiId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600504 = newJObject()
  add(path_600504, "authorizer_id", newJString(authorizerId))
  add(path_600504, "restapi_id", newJString(restapiId))
  result = call_600503.call(path_600504, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_600490(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_600491, base: "/", url: url_GetAuthorizer_600492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_600537 = ref object of OpenApiRestCall_599352
proc url_UpdateAuthorizer_600539(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_600538(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   authorizer_id: JString (required)
  ##                : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `authorizer_id` field"
  var valid_600540 = path.getOrDefault("authorizer_id")
  valid_600540 = validateParameter(valid_600540, JString, required = true,
                                 default = nil)
  if valid_600540 != nil:
    section.add "authorizer_id", valid_600540
  var valid_600541 = path.getOrDefault("restapi_id")
  valid_600541 = validateParameter(valid_600541, JString, required = true,
                                 default = nil)
  if valid_600541 != nil:
    section.add "restapi_id", valid_600541
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
  var valid_600542 = header.getOrDefault("X-Amz-Date")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Date", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Security-Token")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Security-Token", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Content-Sha256", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-Algorithm")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Algorithm", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Signature")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Signature", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-SignedHeaders", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Credential")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Credential", valid_600548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600550: Call_UpdateAuthorizer_600537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_600550.validator(path, query, header, formData, body)
  let scheme = call_600550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600550.url(scheme.get, call_600550.host, call_600550.base,
                         call_600550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600550, url, valid)

proc call*(call_600551: Call_UpdateAuthorizer_600537; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600552 = newJObject()
  var body_600553 = newJObject()
  add(path_600552, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_600553 = body
  add(path_600552, "restapi_id", newJString(restapiId))
  result = call_600551.call(path_600552, nil, nil, nil, body_600553)

var updateAuthorizer* = Call_UpdateAuthorizer_600537(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_600538, base: "/",
    url: url_UpdateAuthorizer_600539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_600522 = ref object of OpenApiRestCall_599352
proc url_DeleteAuthorizer_600524(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_600523(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   authorizer_id: JString (required)
  ##                : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `authorizer_id` field"
  var valid_600525 = path.getOrDefault("authorizer_id")
  valid_600525 = validateParameter(valid_600525, JString, required = true,
                                 default = nil)
  if valid_600525 != nil:
    section.add "authorizer_id", valid_600525
  var valid_600526 = path.getOrDefault("restapi_id")
  valid_600526 = validateParameter(valid_600526, JString, required = true,
                                 default = nil)
  if valid_600526 != nil:
    section.add "restapi_id", valid_600526
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
  var valid_600527 = header.getOrDefault("X-Amz-Date")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Date", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Security-Token")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Security-Token", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Content-Sha256", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Algorithm")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Algorithm", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Signature")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Signature", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-SignedHeaders", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Credential")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Credential", valid_600533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600534: Call_DeleteAuthorizer_600522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_600534.validator(path, query, header, formData, body)
  let scheme = call_600534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600534.url(scheme.get, call_600534.host, call_600534.base,
                         call_600534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600534, url, valid)

proc call*(call_600535: Call_DeleteAuthorizer_600522; authorizerId: string;
          restapiId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600536 = newJObject()
  add(path_600536, "authorizer_id", newJString(authorizerId))
  add(path_600536, "restapi_id", newJString(restapiId))
  result = call_600535.call(path_600536, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_600522(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_600523, base: "/",
    url: url_DeleteAuthorizer_600524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_600554 = ref object of OpenApiRestCall_599352
proc url_GetBasePathMapping_600556(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMapping_600555(path: JsonNode; query: JsonNode;
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
  var valid_600557 = path.getOrDefault("base_path")
  valid_600557 = validateParameter(valid_600557, JString, required = true,
                                 default = nil)
  if valid_600557 != nil:
    section.add "base_path", valid_600557
  var valid_600558 = path.getOrDefault("domain_name")
  valid_600558 = validateParameter(valid_600558, JString, required = true,
                                 default = nil)
  if valid_600558 != nil:
    section.add "domain_name", valid_600558
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
  var valid_600559 = header.getOrDefault("X-Amz-Date")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Date", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Security-Token")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Security-Token", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Content-Sha256", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Algorithm")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Algorithm", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Signature")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Signature", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-SignedHeaders", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Credential")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Credential", valid_600565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600566: Call_GetBasePathMapping_600554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_600566.validator(path, query, header, formData, body)
  let scheme = call_600566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600566.url(scheme.get, call_600566.host, call_600566.base,
                         call_600566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600566, url, valid)

proc call*(call_600567: Call_GetBasePathMapping_600554; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_600568 = newJObject()
  add(path_600568, "base_path", newJString(basePath))
  add(path_600568, "domain_name", newJString(domainName))
  result = call_600567.call(path_600568, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_600554(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_600555, base: "/",
    url: url_GetBasePathMapping_600556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_600584 = ref object of OpenApiRestCall_599352
proc url_UpdateBasePathMapping_600586(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBasePathMapping_600585(path: JsonNode; query: JsonNode;
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
  var valid_600587 = path.getOrDefault("base_path")
  valid_600587 = validateParameter(valid_600587, JString, required = true,
                                 default = nil)
  if valid_600587 != nil:
    section.add "base_path", valid_600587
  var valid_600588 = path.getOrDefault("domain_name")
  valid_600588 = validateParameter(valid_600588, JString, required = true,
                                 default = nil)
  if valid_600588 != nil:
    section.add "domain_name", valid_600588
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
  var valid_600589 = header.getOrDefault("X-Amz-Date")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Date", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Security-Token")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Security-Token", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Content-Sha256", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Algorithm")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Algorithm", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Signature")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Signature", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-SignedHeaders", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Credential")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Credential", valid_600595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600597: Call_UpdateBasePathMapping_600584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_600597.validator(path, query, header, formData, body)
  let scheme = call_600597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600597.url(scheme.get, call_600597.host, call_600597.base,
                         call_600597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600597, url, valid)

proc call*(call_600598: Call_UpdateBasePathMapping_600584; basePath: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  ##   body: JObject (required)
  var path_600599 = newJObject()
  var body_600600 = newJObject()
  add(path_600599, "base_path", newJString(basePath))
  add(path_600599, "domain_name", newJString(domainName))
  if body != nil:
    body_600600 = body
  result = call_600598.call(path_600599, nil, nil, nil, body_600600)

var updateBasePathMapping* = Call_UpdateBasePathMapping_600584(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_600585, base: "/",
    url: url_UpdateBasePathMapping_600586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_600569 = ref object of OpenApiRestCall_599352
proc url_DeleteBasePathMapping_600571(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBasePathMapping_600570(path: JsonNode; query: JsonNode;
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
  var valid_600572 = path.getOrDefault("base_path")
  valid_600572 = validateParameter(valid_600572, JString, required = true,
                                 default = nil)
  if valid_600572 != nil:
    section.add "base_path", valid_600572
  var valid_600573 = path.getOrDefault("domain_name")
  valid_600573 = validateParameter(valid_600573, JString, required = true,
                                 default = nil)
  if valid_600573 != nil:
    section.add "domain_name", valid_600573
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
  var valid_600574 = header.getOrDefault("X-Amz-Date")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Date", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Security-Token")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Security-Token", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Content-Sha256", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Algorithm")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Algorithm", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Signature")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Signature", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-SignedHeaders", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Credential")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Credential", valid_600580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600581: Call_DeleteBasePathMapping_600569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_600581.validator(path, query, header, formData, body)
  let scheme = call_600581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600581.url(scheme.get, call_600581.host, call_600581.base,
                         call_600581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600581, url, valid)

proc call*(call_600582: Call_DeleteBasePathMapping_600569; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_600583 = newJObject()
  add(path_600583, "base_path", newJString(basePath))
  add(path_600583, "domain_name", newJString(domainName))
  result = call_600582.call(path_600583, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_600569(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_600570, base: "/",
    url: url_DeleteBasePathMapping_600571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_600601 = ref object of OpenApiRestCall_599352
proc url_GetClientCertificate_600603(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificate_600602(path: JsonNode; query: JsonNode;
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
  var valid_600604 = path.getOrDefault("clientcertificate_id")
  valid_600604 = validateParameter(valid_600604, JString, required = true,
                                 default = nil)
  if valid_600604 != nil:
    section.add "clientcertificate_id", valid_600604
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
  var valid_600605 = header.getOrDefault("X-Amz-Date")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Date", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Security-Token")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Security-Token", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Content-Sha256", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Algorithm")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Algorithm", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Signature")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Signature", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-SignedHeaders", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Credential")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Credential", valid_600611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600612: Call_GetClientCertificate_600601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_600612.validator(path, query, header, formData, body)
  let scheme = call_600612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600612.url(scheme.get, call_600612.host, call_600612.base,
                         call_600612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600612, url, valid)

proc call*(call_600613: Call_GetClientCertificate_600601;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_600614 = newJObject()
  add(path_600614, "clientcertificate_id", newJString(clientcertificateId))
  result = call_600613.call(path_600614, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_600601(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_600602, base: "/",
    url: url_GetClientCertificate_600603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_600629 = ref object of OpenApiRestCall_599352
proc url_UpdateClientCertificate_600631(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClientCertificate_600630(path: JsonNode; query: JsonNode;
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
  var valid_600632 = path.getOrDefault("clientcertificate_id")
  valid_600632 = validateParameter(valid_600632, JString, required = true,
                                 default = nil)
  if valid_600632 != nil:
    section.add "clientcertificate_id", valid_600632
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
  var valid_600633 = header.getOrDefault("X-Amz-Date")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Date", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Security-Token")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Security-Token", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Content-Sha256", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Algorithm")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Algorithm", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Signature")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Signature", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-SignedHeaders", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Credential")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Credential", valid_600639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600641: Call_UpdateClientCertificate_600629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_600641.validator(path, query, header, formData, body)
  let scheme = call_600641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600641.url(scheme.get, call_600641.host, call_600641.base,
                         call_600641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600641, url, valid)

proc call*(call_600642: Call_UpdateClientCertificate_600629;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_600643 = newJObject()
  var body_600644 = newJObject()
  add(path_600643, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_600644 = body
  result = call_600642.call(path_600643, nil, nil, nil, body_600644)

var updateClientCertificate* = Call_UpdateClientCertificate_600629(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_600630, base: "/",
    url: url_UpdateClientCertificate_600631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_600615 = ref object of OpenApiRestCall_599352
proc url_DeleteClientCertificate_600617(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClientCertificate_600616(path: JsonNode; query: JsonNode;
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
  var valid_600618 = path.getOrDefault("clientcertificate_id")
  valid_600618 = validateParameter(valid_600618, JString, required = true,
                                 default = nil)
  if valid_600618 != nil:
    section.add "clientcertificate_id", valid_600618
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
  var valid_600619 = header.getOrDefault("X-Amz-Date")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Date", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Security-Token")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Security-Token", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Content-Sha256", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Algorithm")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Algorithm", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Signature")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Signature", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-SignedHeaders", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Credential")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Credential", valid_600625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600626: Call_DeleteClientCertificate_600615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_600626.validator(path, query, header, formData, body)
  let scheme = call_600626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600626.url(scheme.get, call_600626.host, call_600626.base,
                         call_600626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600626, url, valid)

proc call*(call_600627: Call_DeleteClientCertificate_600615;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_600628 = newJObject()
  add(path_600628, "clientcertificate_id", newJString(clientcertificateId))
  result = call_600627.call(path_600628, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_600615(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_600616, base: "/",
    url: url_DeleteClientCertificate_600617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_600645 = ref object of OpenApiRestCall_599352
proc url_GetDeployment_600647(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_600646(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600648 = path.getOrDefault("deployment_id")
  valid_600648 = validateParameter(valid_600648, JString, required = true,
                                 default = nil)
  if valid_600648 != nil:
    section.add "deployment_id", valid_600648
  var valid_600649 = path.getOrDefault("restapi_id")
  valid_600649 = validateParameter(valid_600649, JString, required = true,
                                 default = nil)
  if valid_600649 != nil:
    section.add "restapi_id", valid_600649
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_600650 = query.getOrDefault("embed")
  valid_600650 = validateParameter(valid_600650, JArray, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "embed", valid_600650
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
  var valid_600651 = header.getOrDefault("X-Amz-Date")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Date", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Security-Token")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Security-Token", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Content-Sha256", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Algorithm")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Algorithm", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Signature")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Signature", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-SignedHeaders", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Credential")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Credential", valid_600657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600658: Call_GetDeployment_600645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_600658.validator(path, query, header, formData, body)
  let scheme = call_600658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600658.url(scheme.get, call_600658.host, call_600658.base,
                         call_600658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600658, url, valid)

proc call*(call_600659: Call_GetDeployment_600645; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600660 = newJObject()
  var query_600661 = newJObject()
  add(path_600660, "deployment_id", newJString(deploymentId))
  if embed != nil:
    query_600661.add "embed", embed
  add(path_600660, "restapi_id", newJString(restapiId))
  result = call_600659.call(path_600660, query_600661, nil, nil, nil)

var getDeployment* = Call_GetDeployment_600645(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_600646, base: "/", url: url_GetDeployment_600647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_600677 = ref object of OpenApiRestCall_599352
proc url_UpdateDeployment_600679(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_600678(path: JsonNode; query: JsonNode;
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
  var valid_600680 = path.getOrDefault("deployment_id")
  valid_600680 = validateParameter(valid_600680, JString, required = true,
                                 default = nil)
  if valid_600680 != nil:
    section.add "deployment_id", valid_600680
  var valid_600681 = path.getOrDefault("restapi_id")
  valid_600681 = validateParameter(valid_600681, JString, required = true,
                                 default = nil)
  if valid_600681 != nil:
    section.add "restapi_id", valid_600681
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
  var valid_600682 = header.getOrDefault("X-Amz-Date")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Date", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Security-Token")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Security-Token", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Content-Sha256", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Algorithm")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Algorithm", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Signature")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Signature", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-SignedHeaders", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Credential")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Credential", valid_600688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600690: Call_UpdateDeployment_600677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_600690.validator(path, query, header, formData, body)
  let scheme = call_600690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600690.url(scheme.get, call_600690.host, call_600690.base,
                         call_600690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600690, url, valid)

proc call*(call_600691: Call_UpdateDeployment_600677; deploymentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600692 = newJObject()
  var body_600693 = newJObject()
  add(path_600692, "deployment_id", newJString(deploymentId))
  if body != nil:
    body_600693 = body
  add(path_600692, "restapi_id", newJString(restapiId))
  result = call_600691.call(path_600692, nil, nil, nil, body_600693)

var updateDeployment* = Call_UpdateDeployment_600677(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_600678, base: "/",
    url: url_UpdateDeployment_600679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_600662 = ref object of OpenApiRestCall_599352
proc url_DeleteDeployment_600664(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_600663(path: JsonNode; query: JsonNode;
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
  var valid_600665 = path.getOrDefault("deployment_id")
  valid_600665 = validateParameter(valid_600665, JString, required = true,
                                 default = nil)
  if valid_600665 != nil:
    section.add "deployment_id", valid_600665
  var valid_600666 = path.getOrDefault("restapi_id")
  valid_600666 = validateParameter(valid_600666, JString, required = true,
                                 default = nil)
  if valid_600666 != nil:
    section.add "restapi_id", valid_600666
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
  var valid_600667 = header.getOrDefault("X-Amz-Date")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Date", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Security-Token")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Security-Token", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Content-Sha256", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Algorithm")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Algorithm", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Signature")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Signature", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-SignedHeaders", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-Credential")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-Credential", valid_600673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600674: Call_DeleteDeployment_600662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_600674.validator(path, query, header, formData, body)
  let scheme = call_600674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600674.url(scheme.get, call_600674.host, call_600674.base,
                         call_600674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600674, url, valid)

proc call*(call_600675: Call_DeleteDeployment_600662; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600676 = newJObject()
  add(path_600676, "deployment_id", newJString(deploymentId))
  add(path_600676, "restapi_id", newJString(restapiId))
  result = call_600675.call(path_600676, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_600662(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_600663, base: "/",
    url: url_DeleteDeployment_600664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_600694 = ref object of OpenApiRestCall_599352
proc url_GetDocumentationPart_600696(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationPart_600695(path: JsonNode; query: JsonNode;
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
  var valid_600697 = path.getOrDefault("part_id")
  valid_600697 = validateParameter(valid_600697, JString, required = true,
                                 default = nil)
  if valid_600697 != nil:
    section.add "part_id", valid_600697
  var valid_600698 = path.getOrDefault("restapi_id")
  valid_600698 = validateParameter(valid_600698, JString, required = true,
                                 default = nil)
  if valid_600698 != nil:
    section.add "restapi_id", valid_600698
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
  var valid_600699 = header.getOrDefault("X-Amz-Date")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Date", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Security-Token")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Security-Token", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Content-Sha256", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Algorithm")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Algorithm", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Signature")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Signature", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-SignedHeaders", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Credential")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Credential", valid_600705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600706: Call_GetDocumentationPart_600694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600706.validator(path, query, header, formData, body)
  let scheme = call_600706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600706.url(scheme.get, call_600706.host, call_600706.base,
                         call_600706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600706, url, valid)

proc call*(call_600707: Call_GetDocumentationPart_600694; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600708 = newJObject()
  add(path_600708, "part_id", newJString(partId))
  add(path_600708, "restapi_id", newJString(restapiId))
  result = call_600707.call(path_600708, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_600694(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_600695, base: "/",
    url: url_GetDocumentationPart_600696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_600724 = ref object of OpenApiRestCall_599352
proc url_UpdateDocumentationPart_600726(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentationPart_600725(path: JsonNode; query: JsonNode;
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
  var valid_600727 = path.getOrDefault("part_id")
  valid_600727 = validateParameter(valid_600727, JString, required = true,
                                 default = nil)
  if valid_600727 != nil:
    section.add "part_id", valid_600727
  var valid_600728 = path.getOrDefault("restapi_id")
  valid_600728 = validateParameter(valid_600728, JString, required = true,
                                 default = nil)
  if valid_600728 != nil:
    section.add "restapi_id", valid_600728
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
  var valid_600729 = header.getOrDefault("X-Amz-Date")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Date", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-Security-Token")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-Security-Token", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Content-Sha256", valid_600731
  var valid_600732 = header.getOrDefault("X-Amz-Algorithm")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Algorithm", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-Signature")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Signature", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-SignedHeaders", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Credential")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Credential", valid_600735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600737: Call_UpdateDocumentationPart_600724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600737.validator(path, query, header, formData, body)
  let scheme = call_600737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600737.url(scheme.get, call_600737.host, call_600737.base,
                         call_600737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600737, url, valid)

proc call*(call_600738: Call_UpdateDocumentationPart_600724; body: JsonNode;
          partId: string; restapiId: string): Recallable =
  ## updateDocumentationPart
  ##   body: JObject (required)
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600739 = newJObject()
  var body_600740 = newJObject()
  if body != nil:
    body_600740 = body
  add(path_600739, "part_id", newJString(partId))
  add(path_600739, "restapi_id", newJString(restapiId))
  result = call_600738.call(path_600739, nil, nil, nil, body_600740)

var updateDocumentationPart* = Call_UpdateDocumentationPart_600724(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_600725, base: "/",
    url: url_UpdateDocumentationPart_600726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_600709 = ref object of OpenApiRestCall_599352
proc url_DeleteDocumentationPart_600711(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocumentationPart_600710(path: JsonNode; query: JsonNode;
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
  var valid_600712 = path.getOrDefault("part_id")
  valid_600712 = validateParameter(valid_600712, JString, required = true,
                                 default = nil)
  if valid_600712 != nil:
    section.add "part_id", valid_600712
  var valid_600713 = path.getOrDefault("restapi_id")
  valid_600713 = validateParameter(valid_600713, JString, required = true,
                                 default = nil)
  if valid_600713 != nil:
    section.add "restapi_id", valid_600713
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
  var valid_600714 = header.getOrDefault("X-Amz-Date")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Date", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Security-Token")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Security-Token", valid_600715
  var valid_600716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Content-Sha256", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Algorithm")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Algorithm", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Signature")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Signature", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-SignedHeaders", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Credential")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Credential", valid_600720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600721: Call_DeleteDocumentationPart_600709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600721.validator(path, query, header, formData, body)
  let scheme = call_600721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600721.url(scheme.get, call_600721.host, call_600721.base,
                         call_600721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600721, url, valid)

proc call*(call_600722: Call_DeleteDocumentationPart_600709; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600723 = newJObject()
  add(path_600723, "part_id", newJString(partId))
  add(path_600723, "restapi_id", newJString(restapiId))
  result = call_600722.call(path_600723, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_600709(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_600710, base: "/",
    url: url_DeleteDocumentationPart_600711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_600741 = ref object of OpenApiRestCall_599352
proc url_GetDocumentationVersion_600743(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationVersion_600742(path: JsonNode; query: JsonNode;
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
  var valid_600744 = path.getOrDefault("doc_version")
  valid_600744 = validateParameter(valid_600744, JString, required = true,
                                 default = nil)
  if valid_600744 != nil:
    section.add "doc_version", valid_600744
  var valid_600745 = path.getOrDefault("restapi_id")
  valid_600745 = validateParameter(valid_600745, JString, required = true,
                                 default = nil)
  if valid_600745 != nil:
    section.add "restapi_id", valid_600745
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
  var valid_600746 = header.getOrDefault("X-Amz-Date")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Date", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-Security-Token")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Security-Token", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Content-Sha256", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Algorithm")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Algorithm", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Signature")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Signature", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-SignedHeaders", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Credential")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Credential", valid_600752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600753: Call_GetDocumentationVersion_600741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600753.validator(path, query, header, formData, body)
  let scheme = call_600753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600753.url(scheme.get, call_600753.host, call_600753.base,
                         call_600753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600753, url, valid)

proc call*(call_600754: Call_GetDocumentationVersion_600741; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600755 = newJObject()
  add(path_600755, "doc_version", newJString(docVersion))
  add(path_600755, "restapi_id", newJString(restapiId))
  result = call_600754.call(path_600755, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_600741(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_600742, base: "/",
    url: url_GetDocumentationVersion_600743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_600771 = ref object of OpenApiRestCall_599352
proc url_UpdateDocumentationVersion_600773(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentationVersion_600772(path: JsonNode; query: JsonNode;
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
  var valid_600774 = path.getOrDefault("doc_version")
  valid_600774 = validateParameter(valid_600774, JString, required = true,
                                 default = nil)
  if valid_600774 != nil:
    section.add "doc_version", valid_600774
  var valid_600775 = path.getOrDefault("restapi_id")
  valid_600775 = validateParameter(valid_600775, JString, required = true,
                                 default = nil)
  if valid_600775 != nil:
    section.add "restapi_id", valid_600775
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
  var valid_600776 = header.getOrDefault("X-Amz-Date")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Date", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Security-Token")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Security-Token", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Content-Sha256", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Algorithm")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Algorithm", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-Signature")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-Signature", valid_600780
  var valid_600781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "X-Amz-SignedHeaders", valid_600781
  var valid_600782 = header.getOrDefault("X-Amz-Credential")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Credential", valid_600782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600784: Call_UpdateDocumentationVersion_600771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600784.validator(path, query, header, formData, body)
  let scheme = call_600784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600784.url(scheme.get, call_600784.host, call_600784.base,
                         call_600784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600784, url, valid)

proc call*(call_600785: Call_UpdateDocumentationVersion_600771; docVersion: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  var path_600786 = newJObject()
  var body_600787 = newJObject()
  add(path_600786, "doc_version", newJString(docVersion))
  if body != nil:
    body_600787 = body
  add(path_600786, "restapi_id", newJString(restapiId))
  result = call_600785.call(path_600786, nil, nil, nil, body_600787)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_600771(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_600772, base: "/",
    url: url_UpdateDocumentationVersion_600773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_600756 = ref object of OpenApiRestCall_599352
proc url_DeleteDocumentationVersion_600758(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentationVersion_600757(path: JsonNode; query: JsonNode;
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
  var valid_600759 = path.getOrDefault("doc_version")
  valid_600759 = validateParameter(valid_600759, JString, required = true,
                                 default = nil)
  if valid_600759 != nil:
    section.add "doc_version", valid_600759
  var valid_600760 = path.getOrDefault("restapi_id")
  valid_600760 = validateParameter(valid_600760, JString, required = true,
                                 default = nil)
  if valid_600760 != nil:
    section.add "restapi_id", valid_600760
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
  var valid_600761 = header.getOrDefault("X-Amz-Date")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Date", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Security-Token")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Security-Token", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Content-Sha256", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Algorithm")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Algorithm", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Signature")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Signature", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-SignedHeaders", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-Credential")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Credential", valid_600767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600768: Call_DeleteDocumentationVersion_600756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600768.validator(path, query, header, formData, body)
  let scheme = call_600768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600768.url(scheme.get, call_600768.host, call_600768.base,
                         call_600768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600768, url, valid)

proc call*(call_600769: Call_DeleteDocumentationVersion_600756; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600770 = newJObject()
  add(path_600770, "doc_version", newJString(docVersion))
  add(path_600770, "restapi_id", newJString(restapiId))
  result = call_600769.call(path_600770, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_600756(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_600757, base: "/",
    url: url_DeleteDocumentationVersion_600758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_600788 = ref object of OpenApiRestCall_599352
proc url_GetDomainName_600790(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_600789(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600791 = path.getOrDefault("domain_name")
  valid_600791 = validateParameter(valid_600791, JString, required = true,
                                 default = nil)
  if valid_600791 != nil:
    section.add "domain_name", valid_600791
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
  var valid_600792 = header.getOrDefault("X-Amz-Date")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-Date", valid_600792
  var valid_600793 = header.getOrDefault("X-Amz-Security-Token")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "X-Amz-Security-Token", valid_600793
  var valid_600794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Content-Sha256", valid_600794
  var valid_600795 = header.getOrDefault("X-Amz-Algorithm")
  valid_600795 = validateParameter(valid_600795, JString, required = false,
                                 default = nil)
  if valid_600795 != nil:
    section.add "X-Amz-Algorithm", valid_600795
  var valid_600796 = header.getOrDefault("X-Amz-Signature")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "X-Amz-Signature", valid_600796
  var valid_600797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-SignedHeaders", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Credential")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Credential", valid_600798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600799: Call_GetDomainName_600788; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_600799.validator(path, query, header, formData, body)
  let scheme = call_600799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600799.url(scheme.get, call_600799.host, call_600799.base,
                         call_600799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600799, url, valid)

proc call*(call_600800: Call_GetDomainName_600788; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_600801 = newJObject()
  add(path_600801, "domain_name", newJString(domainName))
  result = call_600800.call(path_600801, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_600788(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_600789,
    base: "/", url: url_GetDomainName_600790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_600816 = ref object of OpenApiRestCall_599352
proc url_UpdateDomainName_600818(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_600817(path: JsonNode; query: JsonNode;
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
  var valid_600819 = path.getOrDefault("domain_name")
  valid_600819 = validateParameter(valid_600819, JString, required = true,
                                 default = nil)
  if valid_600819 != nil:
    section.add "domain_name", valid_600819
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
  var valid_600820 = header.getOrDefault("X-Amz-Date")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Date", valid_600820
  var valid_600821 = header.getOrDefault("X-Amz-Security-Token")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-Security-Token", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Content-Sha256", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-Algorithm")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-Algorithm", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Signature")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Signature", valid_600824
  var valid_600825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-SignedHeaders", valid_600825
  var valid_600826 = header.getOrDefault("X-Amz-Credential")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "X-Amz-Credential", valid_600826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600828: Call_UpdateDomainName_600816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_600828.validator(path, query, header, formData, body)
  let scheme = call_600828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600828.url(scheme.get, call_600828.host, call_600828.base,
                         call_600828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600828, url, valid)

proc call*(call_600829: Call_UpdateDomainName_600816; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  ##   body: JObject (required)
  var path_600830 = newJObject()
  var body_600831 = newJObject()
  add(path_600830, "domain_name", newJString(domainName))
  if body != nil:
    body_600831 = body
  result = call_600829.call(path_600830, nil, nil, nil, body_600831)

var updateDomainName* = Call_UpdateDomainName_600816(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_600817,
    base: "/", url: url_UpdateDomainName_600818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_600802 = ref object of OpenApiRestCall_599352
proc url_DeleteDomainName_600804(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_600803(path: JsonNode; query: JsonNode;
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
  var valid_600805 = path.getOrDefault("domain_name")
  valid_600805 = validateParameter(valid_600805, JString, required = true,
                                 default = nil)
  if valid_600805 != nil:
    section.add "domain_name", valid_600805
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
  var valid_600806 = header.getOrDefault("X-Amz-Date")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Date", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-Security-Token")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-Security-Token", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-Content-Sha256", valid_600808
  var valid_600809 = header.getOrDefault("X-Amz-Algorithm")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-Algorithm", valid_600809
  var valid_600810 = header.getOrDefault("X-Amz-Signature")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "X-Amz-Signature", valid_600810
  var valid_600811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-SignedHeaders", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-Credential")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Credential", valid_600812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600813: Call_DeleteDomainName_600802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_600813.validator(path, query, header, formData, body)
  let scheme = call_600813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600813.url(scheme.get, call_600813.host, call_600813.base,
                         call_600813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600813, url, valid)

proc call*(call_600814: Call_DeleteDomainName_600802; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_600815 = newJObject()
  add(path_600815, "domain_name", newJString(domainName))
  result = call_600814.call(path_600815, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_600802(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_600803,
    base: "/", url: url_DeleteDomainName_600804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_600847 = ref object of OpenApiRestCall_599352
proc url_PutGatewayResponse_600849(protocol: Scheme; host: string; base: string;
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

proc validate_PutGatewayResponse_600848(path: JsonNode; query: JsonNode;
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
  var valid_600850 = path.getOrDefault("response_type")
  valid_600850 = validateParameter(valid_600850, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_600850 != nil:
    section.add "response_type", valid_600850
  var valid_600851 = path.getOrDefault("restapi_id")
  valid_600851 = validateParameter(valid_600851, JString, required = true,
                                 default = nil)
  if valid_600851 != nil:
    section.add "restapi_id", valid_600851
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
  var valid_600852 = header.getOrDefault("X-Amz-Date")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Date", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Security-Token")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Security-Token", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Content-Sha256", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-Algorithm")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Algorithm", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Signature")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Signature", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-SignedHeaders", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Credential")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Credential", valid_600858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600860: Call_PutGatewayResponse_600847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_600860.validator(path, query, header, formData, body)
  let scheme = call_600860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600860.url(scheme.get, call_600860.host, call_600860.base,
                         call_600860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600860, url, valid)

proc call*(call_600861: Call_PutGatewayResponse_600847; body: JsonNode;
          restapiId: string; responseType: string = "DEFAULT_4XX"): Recallable =
  ## putGatewayResponse
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ##   responseType: string (required)
  ##               : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600862 = newJObject()
  var body_600863 = newJObject()
  add(path_600862, "response_type", newJString(responseType))
  if body != nil:
    body_600863 = body
  add(path_600862, "restapi_id", newJString(restapiId))
  result = call_600861.call(path_600862, nil, nil, nil, body_600863)

var putGatewayResponse* = Call_PutGatewayResponse_600847(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_600848, base: "/",
    url: url_PutGatewayResponse_600849, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_600832 = ref object of OpenApiRestCall_599352
proc url_GetGatewayResponse_600834(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponse_600833(path: JsonNode; query: JsonNode;
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
  var valid_600835 = path.getOrDefault("response_type")
  valid_600835 = validateParameter(valid_600835, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_600835 != nil:
    section.add "response_type", valid_600835
  var valid_600836 = path.getOrDefault("restapi_id")
  valid_600836 = validateParameter(valid_600836, JString, required = true,
                                 default = nil)
  if valid_600836 != nil:
    section.add "restapi_id", valid_600836
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
  var valid_600837 = header.getOrDefault("X-Amz-Date")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Date", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Security-Token")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Security-Token", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Content-Sha256", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Algorithm")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Algorithm", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Signature")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Signature", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-SignedHeaders", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Credential")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Credential", valid_600843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600844: Call_GetGatewayResponse_600832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_600844.validator(path, query, header, formData, body)
  let scheme = call_600844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600844.url(scheme.get, call_600844.host, call_600844.base,
                         call_600844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600844, url, valid)

proc call*(call_600845: Call_GetGatewayResponse_600832; restapiId: string;
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
  var path_600846 = newJObject()
  add(path_600846, "response_type", newJString(responseType))
  add(path_600846, "restapi_id", newJString(restapiId))
  result = call_600845.call(path_600846, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_600832(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_600833, base: "/",
    url: url_GetGatewayResponse_600834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_600879 = ref object of OpenApiRestCall_599352
proc url_UpdateGatewayResponse_600881(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayResponse_600880(path: JsonNode; query: JsonNode;
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
  var valid_600882 = path.getOrDefault("response_type")
  valid_600882 = validateParameter(valid_600882, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_600882 != nil:
    section.add "response_type", valid_600882
  var valid_600883 = path.getOrDefault("restapi_id")
  valid_600883 = validateParameter(valid_600883, JString, required = true,
                                 default = nil)
  if valid_600883 != nil:
    section.add "restapi_id", valid_600883
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600892: Call_UpdateGatewayResponse_600879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_600892.validator(path, query, header, formData, body)
  let scheme = call_600892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600892.url(scheme.get, call_600892.host, call_600892.base,
                         call_600892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600892, url, valid)

proc call*(call_600893: Call_UpdateGatewayResponse_600879; body: JsonNode;
          restapiId: string; responseType: string = "DEFAULT_4XX"): Recallable =
  ## updateGatewayResponse
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ##   responseType: string (required)
  ##               : <p>[Required] <p>The response type of the associated <a>GatewayResponse</a>. Valid values are 
  ## <ul><li>ACCESS_DENIED</li><li>API_CONFIGURATION_ERROR</li><li>AUTHORIZER_FAILURE</li><li> 
  ## AUTHORIZER_CONFIGURATION_ERROR</li><li>BAD_REQUEST_PARAMETERS</li><li>BAD_REQUEST_BODY</li><li>DEFAULT_4XX</li><li>DEFAULT_5XX</li><li>EXPIRED_TOKEN</li><li>INVALID_SIGNATURE</li><li>INTEGRATION_FAILURE</li><li>INTEGRATION_TIMEOUT</li><li>INVALID_API_KEY</li><li>MISSING_AUTHENTICATION_TOKEN</li><li> 
  ## QUOTA_EXCEEDED</li><li>REQUEST_TOO_LARGE</li><li>RESOURCE_NOT_FOUND</li><li>THROTTLED</li><li>UNAUTHORIZED</li><li>UNSUPPORTED_MEDIA_TYPE</li></ul> </p></p>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_600894 = newJObject()
  var body_600895 = newJObject()
  add(path_600894, "response_type", newJString(responseType))
  if body != nil:
    body_600895 = body
  add(path_600894, "restapi_id", newJString(restapiId))
  result = call_600893.call(path_600894, nil, nil, nil, body_600895)

var updateGatewayResponse* = Call_UpdateGatewayResponse_600879(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_600880, base: "/",
    url: url_UpdateGatewayResponse_600881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_600864 = ref object of OpenApiRestCall_599352
proc url_DeleteGatewayResponse_600866(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayResponse_600865(path: JsonNode; query: JsonNode;
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
  var valid_600867 = path.getOrDefault("response_type")
  valid_600867 = validateParameter(valid_600867, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_600867 != nil:
    section.add "response_type", valid_600867
  var valid_600868 = path.getOrDefault("restapi_id")
  valid_600868 = validateParameter(valid_600868, JString, required = true,
                                 default = nil)
  if valid_600868 != nil:
    section.add "restapi_id", valid_600868
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
  var valid_600869 = header.getOrDefault("X-Amz-Date")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Date", valid_600869
  var valid_600870 = header.getOrDefault("X-Amz-Security-Token")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-Security-Token", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Content-Sha256", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Algorithm")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Algorithm", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Signature")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Signature", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-SignedHeaders", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Credential")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Credential", valid_600875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600876: Call_DeleteGatewayResponse_600864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_600876.validator(path, query, header, formData, body)
  let scheme = call_600876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600876.url(scheme.get, call_600876.host, call_600876.base,
                         call_600876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600876, url, valid)

proc call*(call_600877: Call_DeleteGatewayResponse_600864; restapiId: string;
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
  var path_600878 = newJObject()
  add(path_600878, "response_type", newJString(responseType))
  add(path_600878, "restapi_id", newJString(restapiId))
  result = call_600877.call(path_600878, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_600864(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_600865, base: "/",
    url: url_DeleteGatewayResponse_600866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_600912 = ref object of OpenApiRestCall_599352
proc url_PutIntegration_600914(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegration_600913(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Sets up a method's integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies a put integration request's HTTP method.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a put integration request's resource ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_600915 = path.getOrDefault("http_method")
  valid_600915 = validateParameter(valid_600915, JString, required = true,
                                 default = nil)
  if valid_600915 != nil:
    section.add "http_method", valid_600915
  var valid_600916 = path.getOrDefault("restapi_id")
  valid_600916 = validateParameter(valid_600916, JString, required = true,
                                 default = nil)
  if valid_600916 != nil:
    section.add "restapi_id", valid_600916
  var valid_600917 = path.getOrDefault("resource_id")
  valid_600917 = validateParameter(valid_600917, JString, required = true,
                                 default = nil)
  if valid_600917 != nil:
    section.add "resource_id", valid_600917
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
  var valid_600918 = header.getOrDefault("X-Amz-Date")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Date", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-Security-Token")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Security-Token", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Content-Sha256", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-Algorithm")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Algorithm", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-Signature")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Signature", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-SignedHeaders", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-Credential")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Credential", valid_600924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_PutIntegration_600912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600926, url, valid)

proc call*(call_600927: Call_PutIntegration_600912; httpMethod: string;
          body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## putIntegration
  ## Sets up a method's integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a put integration request's HTTP method.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a put integration request's resource ID.
  var path_600928 = newJObject()
  var body_600929 = newJObject()
  add(path_600928, "http_method", newJString(httpMethod))
  if body != nil:
    body_600929 = body
  add(path_600928, "restapi_id", newJString(restapiId))
  add(path_600928, "resource_id", newJString(resourceId))
  result = call_600927.call(path_600928, nil, nil, nil, body_600929)

var putIntegration* = Call_PutIntegration_600912(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_600913, base: "/", url: url_PutIntegration_600914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_600896 = ref object of OpenApiRestCall_599352
proc url_GetIntegration_600898(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_600897(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Get the integration settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies a get integration request's HTTP method.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a get integration request's resource identifier
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_600899 = path.getOrDefault("http_method")
  valid_600899 = validateParameter(valid_600899, JString, required = true,
                                 default = nil)
  if valid_600899 != nil:
    section.add "http_method", valid_600899
  var valid_600900 = path.getOrDefault("restapi_id")
  valid_600900 = validateParameter(valid_600900, JString, required = true,
                                 default = nil)
  if valid_600900 != nil:
    section.add "restapi_id", valid_600900
  var valid_600901 = path.getOrDefault("resource_id")
  valid_600901 = validateParameter(valid_600901, JString, required = true,
                                 default = nil)
  if valid_600901 != nil:
    section.add "resource_id", valid_600901
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
  var valid_600902 = header.getOrDefault("X-Amz-Date")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Date", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Security-Token")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Security-Token", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Content-Sha256", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Algorithm")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Algorithm", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Signature")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Signature", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-SignedHeaders", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Credential")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Credential", valid_600908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600909: Call_GetIntegration_600896; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_600909.validator(path, query, header, formData, body)
  let scheme = call_600909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600909.url(scheme.get, call_600909.host, call_600909.base,
                         call_600909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600909, url, valid)

proc call*(call_600910: Call_GetIntegration_600896; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  var path_600911 = newJObject()
  add(path_600911, "http_method", newJString(httpMethod))
  add(path_600911, "restapi_id", newJString(restapiId))
  add(path_600911, "resource_id", newJString(resourceId))
  result = call_600910.call(path_600911, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_600896(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_600897, base: "/", url: url_GetIntegration_600898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_600946 = ref object of OpenApiRestCall_599352
proc url_UpdateIntegration_600948(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_600947(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Represents an update integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Represents an update integration request's HTTP method.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Represents an update integration request's resource identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_600949 = path.getOrDefault("http_method")
  valid_600949 = validateParameter(valid_600949, JString, required = true,
                                 default = nil)
  if valid_600949 != nil:
    section.add "http_method", valid_600949
  var valid_600950 = path.getOrDefault("restapi_id")
  valid_600950 = validateParameter(valid_600950, JString, required = true,
                                 default = nil)
  if valid_600950 != nil:
    section.add "restapi_id", valid_600950
  var valid_600951 = path.getOrDefault("resource_id")
  valid_600951 = validateParameter(valid_600951, JString, required = true,
                                 default = nil)
  if valid_600951 != nil:
    section.add "resource_id", valid_600951
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
  var valid_600952 = header.getOrDefault("X-Amz-Date")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Date", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Security-Token")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Security-Token", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-Content-Sha256", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Algorithm")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Algorithm", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Signature")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Signature", valid_600956
  var valid_600957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "X-Amz-SignedHeaders", valid_600957
  var valid_600958 = header.getOrDefault("X-Amz-Credential")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-Credential", valid_600958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600960: Call_UpdateIntegration_600946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_600960.validator(path, query, header, formData, body)
  let scheme = call_600960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600960.url(scheme.get, call_600960.host, call_600960.base,
                         call_600960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600960, url, valid)

proc call*(call_600961: Call_UpdateIntegration_600946; httpMethod: string;
          body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## updateIntegration
  ## Represents an update integration.
  ##   httpMethod: string (required)
  ##             : [Required] Represents an update integration request's HTTP method.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Represents an update integration request's resource identifier.
  var path_600962 = newJObject()
  var body_600963 = newJObject()
  add(path_600962, "http_method", newJString(httpMethod))
  if body != nil:
    body_600963 = body
  add(path_600962, "restapi_id", newJString(restapiId))
  add(path_600962, "resource_id", newJString(resourceId))
  result = call_600961.call(path_600962, nil, nil, nil, body_600963)

var updateIntegration* = Call_UpdateIntegration_600946(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_600947, base: "/",
    url: url_UpdateIntegration_600948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_600930 = ref object of OpenApiRestCall_599352
proc url_DeleteIntegration_600932(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_600931(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Represents a delete integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies a delete integration request's HTTP method.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a delete integration request's resource identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_600933 = path.getOrDefault("http_method")
  valid_600933 = validateParameter(valid_600933, JString, required = true,
                                 default = nil)
  if valid_600933 != nil:
    section.add "http_method", valid_600933
  var valid_600934 = path.getOrDefault("restapi_id")
  valid_600934 = validateParameter(valid_600934, JString, required = true,
                                 default = nil)
  if valid_600934 != nil:
    section.add "restapi_id", valid_600934
  var valid_600935 = path.getOrDefault("resource_id")
  valid_600935 = validateParameter(valid_600935, JString, required = true,
                                 default = nil)
  if valid_600935 != nil:
    section.add "resource_id", valid_600935
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
  var valid_600936 = header.getOrDefault("X-Amz-Date")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-Date", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Security-Token")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Security-Token", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Content-Sha256", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-Algorithm")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-Algorithm", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Signature")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Signature", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-SignedHeaders", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-Credential")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Credential", valid_600942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600943: Call_DeleteIntegration_600930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_600943.validator(path, query, header, formData, body)
  let scheme = call_600943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600943.url(scheme.get, call_600943.host, call_600943.base,
                         call_600943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600943, url, valid)

proc call*(call_600944: Call_DeleteIntegration_600930; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  var path_600945 = newJObject()
  add(path_600945, "http_method", newJString(httpMethod))
  add(path_600945, "restapi_id", newJString(restapiId))
  add(path_600945, "resource_id", newJString(resourceId))
  result = call_600944.call(path_600945, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_600930(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_600931, base: "/",
    url: url_DeleteIntegration_600932, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_600981 = ref object of OpenApiRestCall_599352
proc url_PutIntegrationResponse_600983(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegrationResponse_600982(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents a put integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies a put integration response request's HTTP method.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a put integration response request's resource identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_600984 = path.getOrDefault("http_method")
  valid_600984 = validateParameter(valid_600984, JString, required = true,
                                 default = nil)
  if valid_600984 != nil:
    section.add "http_method", valid_600984
  var valid_600985 = path.getOrDefault("status_code")
  valid_600985 = validateParameter(valid_600985, JString, required = true,
                                 default = nil)
  if valid_600985 != nil:
    section.add "status_code", valid_600985
  var valid_600986 = path.getOrDefault("restapi_id")
  valid_600986 = validateParameter(valid_600986, JString, required = true,
                                 default = nil)
  if valid_600986 != nil:
    section.add "restapi_id", valid_600986
  var valid_600987 = path.getOrDefault("resource_id")
  valid_600987 = validateParameter(valid_600987, JString, required = true,
                                 default = nil)
  if valid_600987 != nil:
    section.add "resource_id", valid_600987
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
  var valid_600988 = header.getOrDefault("X-Amz-Date")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-Date", valid_600988
  var valid_600989 = header.getOrDefault("X-Amz-Security-Token")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Security-Token", valid_600989
  var valid_600990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "X-Amz-Content-Sha256", valid_600990
  var valid_600991 = header.getOrDefault("X-Amz-Algorithm")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "X-Amz-Algorithm", valid_600991
  var valid_600992 = header.getOrDefault("X-Amz-Signature")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "X-Amz-Signature", valid_600992
  var valid_600993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "X-Amz-SignedHeaders", valid_600993
  var valid_600994 = header.getOrDefault("X-Amz-Credential")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Credential", valid_600994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600996: Call_PutIntegrationResponse_600981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_600996.validator(path, query, header, formData, body)
  let scheme = call_600996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600996.url(scheme.get, call_600996.host, call_600996.base,
                         call_600996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600996, url, valid)

proc call*(call_600997: Call_PutIntegrationResponse_600981; httpMethod: string;
          statusCode: string; body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## putIntegrationResponse
  ## Represents a put integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a put integration response request's HTTP method.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a put integration response request's resource identifier.
  var path_600998 = newJObject()
  var body_600999 = newJObject()
  add(path_600998, "http_method", newJString(httpMethod))
  add(path_600998, "status_code", newJString(statusCode))
  if body != nil:
    body_600999 = body
  add(path_600998, "restapi_id", newJString(restapiId))
  add(path_600998, "resource_id", newJString(resourceId))
  result = call_600997.call(path_600998, nil, nil, nil, body_600999)

var putIntegrationResponse* = Call_PutIntegrationResponse_600981(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_600982, base: "/",
    url: url_PutIntegrationResponse_600983, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_600964 = ref object of OpenApiRestCall_599352
proc url_GetIntegrationResponse_600966(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_600965(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents a get integration response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies a get integration response request's HTTP method.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a get integration response request's resource identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_600967 = path.getOrDefault("http_method")
  valid_600967 = validateParameter(valid_600967, JString, required = true,
                                 default = nil)
  if valid_600967 != nil:
    section.add "http_method", valid_600967
  var valid_600968 = path.getOrDefault("status_code")
  valid_600968 = validateParameter(valid_600968, JString, required = true,
                                 default = nil)
  if valid_600968 != nil:
    section.add "status_code", valid_600968
  var valid_600969 = path.getOrDefault("restapi_id")
  valid_600969 = validateParameter(valid_600969, JString, required = true,
                                 default = nil)
  if valid_600969 != nil:
    section.add "restapi_id", valid_600969
  var valid_600970 = path.getOrDefault("resource_id")
  valid_600970 = validateParameter(valid_600970, JString, required = true,
                                 default = nil)
  if valid_600970 != nil:
    section.add "resource_id", valid_600970
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
  var valid_600971 = header.getOrDefault("X-Amz-Date")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Date", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Security-Token")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Security-Token", valid_600972
  var valid_600973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-Content-Sha256", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-Algorithm")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Algorithm", valid_600974
  var valid_600975 = header.getOrDefault("X-Amz-Signature")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Signature", valid_600975
  var valid_600976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "X-Amz-SignedHeaders", valid_600976
  var valid_600977 = header.getOrDefault("X-Amz-Credential")
  valid_600977 = validateParameter(valid_600977, JString, required = false,
                                 default = nil)
  if valid_600977 != nil:
    section.add "X-Amz-Credential", valid_600977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600978: Call_GetIntegrationResponse_600964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_600978.validator(path, query, header, formData, body)
  let scheme = call_600978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600978.url(scheme.get, call_600978.host, call_600978.base,
                         call_600978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600978, url, valid)

proc call*(call_600979: Call_GetIntegrationResponse_600964; httpMethod: string;
          statusCode: string; restapiId: string; resourceId: string): Recallable =
  ## getIntegrationResponse
  ## Represents a get integration response.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration response request's HTTP method.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration response request's resource identifier.
  var path_600980 = newJObject()
  add(path_600980, "http_method", newJString(httpMethod))
  add(path_600980, "status_code", newJString(statusCode))
  add(path_600980, "restapi_id", newJString(restapiId))
  add(path_600980, "resource_id", newJString(resourceId))
  result = call_600979.call(path_600980, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_600964(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_600965, base: "/",
    url: url_GetIntegrationResponse_600966, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_601017 = ref object of OpenApiRestCall_599352
proc url_UpdateIntegrationResponse_601019(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_601018(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents an update integration response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies an update integration response request's HTTP method.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies an update integration response request's resource identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601020 = path.getOrDefault("http_method")
  valid_601020 = validateParameter(valid_601020, JString, required = true,
                                 default = nil)
  if valid_601020 != nil:
    section.add "http_method", valid_601020
  var valid_601021 = path.getOrDefault("status_code")
  valid_601021 = validateParameter(valid_601021, JString, required = true,
                                 default = nil)
  if valid_601021 != nil:
    section.add "status_code", valid_601021
  var valid_601022 = path.getOrDefault("restapi_id")
  valid_601022 = validateParameter(valid_601022, JString, required = true,
                                 default = nil)
  if valid_601022 != nil:
    section.add "restapi_id", valid_601022
  var valid_601023 = path.getOrDefault("resource_id")
  valid_601023 = validateParameter(valid_601023, JString, required = true,
                                 default = nil)
  if valid_601023 != nil:
    section.add "resource_id", valid_601023
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
  var valid_601024 = header.getOrDefault("X-Amz-Date")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Date", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-Security-Token")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Security-Token", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Content-Sha256", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Algorithm")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Algorithm", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Signature")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Signature", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-SignedHeaders", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Credential")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Credential", valid_601030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601032: Call_UpdateIntegrationResponse_601017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_601032.validator(path, query, header, formData, body)
  let scheme = call_601032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601032.url(scheme.get, call_601032.host, call_601032.base,
                         call_601032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601032, url, valid)

proc call*(call_601033: Call_UpdateIntegrationResponse_601017; httpMethod: string;
          statusCode: string; body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## updateIntegrationResponse
  ## Represents an update integration response.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies an update integration response request's HTTP method.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies an update integration response request's resource identifier.
  var path_601034 = newJObject()
  var body_601035 = newJObject()
  add(path_601034, "http_method", newJString(httpMethod))
  add(path_601034, "status_code", newJString(statusCode))
  if body != nil:
    body_601035 = body
  add(path_601034, "restapi_id", newJString(restapiId))
  add(path_601034, "resource_id", newJString(resourceId))
  result = call_601033.call(path_601034, nil, nil, nil, body_601035)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_601017(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_601018, base: "/",
    url: url_UpdateIntegrationResponse_601019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_601000 = ref object of OpenApiRestCall_599352
proc url_DeleteIntegrationResponse_601002(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_601001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents a delete integration response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies a delete integration response request's HTTP method.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a delete integration response request's resource identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601003 = path.getOrDefault("http_method")
  valid_601003 = validateParameter(valid_601003, JString, required = true,
                                 default = nil)
  if valid_601003 != nil:
    section.add "http_method", valid_601003
  var valid_601004 = path.getOrDefault("status_code")
  valid_601004 = validateParameter(valid_601004, JString, required = true,
                                 default = nil)
  if valid_601004 != nil:
    section.add "status_code", valid_601004
  var valid_601005 = path.getOrDefault("restapi_id")
  valid_601005 = validateParameter(valid_601005, JString, required = true,
                                 default = nil)
  if valid_601005 != nil:
    section.add "restapi_id", valid_601005
  var valid_601006 = path.getOrDefault("resource_id")
  valid_601006 = validateParameter(valid_601006, JString, required = true,
                                 default = nil)
  if valid_601006 != nil:
    section.add "resource_id", valid_601006
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
  var valid_601007 = header.getOrDefault("X-Amz-Date")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Date", valid_601007
  var valid_601008 = header.getOrDefault("X-Amz-Security-Token")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "X-Amz-Security-Token", valid_601008
  var valid_601009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Content-Sha256", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Algorithm")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Algorithm", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-Signature")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Signature", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-SignedHeaders", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Credential")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Credential", valid_601013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601014: Call_DeleteIntegrationResponse_601000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_601014.validator(path, query, header, formData, body)
  let scheme = call_601014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601014.url(scheme.get, call_601014.host, call_601014.base,
                         call_601014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601014, url, valid)

proc call*(call_601015: Call_DeleteIntegrationResponse_601000; httpMethod: string;
          statusCode: string; restapiId: string; resourceId: string): Recallable =
  ## deleteIntegrationResponse
  ## Represents a delete integration response.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration response request's HTTP method.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration response request's resource identifier.
  var path_601016 = newJObject()
  add(path_601016, "http_method", newJString(httpMethod))
  add(path_601016, "status_code", newJString(statusCode))
  add(path_601016, "restapi_id", newJString(restapiId))
  add(path_601016, "resource_id", newJString(resourceId))
  result = call_601015.call(path_601016, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_601000(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_601001, base: "/",
    url: url_DeleteIntegrationResponse_601002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_601052 = ref object of OpenApiRestCall_599352
proc url_PutMethod_601054(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutMethod_601053(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies the method request's HTTP method type.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the new <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601055 = path.getOrDefault("http_method")
  valid_601055 = validateParameter(valid_601055, JString, required = true,
                                 default = nil)
  if valid_601055 != nil:
    section.add "http_method", valid_601055
  var valid_601056 = path.getOrDefault("restapi_id")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = nil)
  if valid_601056 != nil:
    section.add "restapi_id", valid_601056
  var valid_601057 = path.getOrDefault("resource_id")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "resource_id", valid_601057
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
  var valid_601058 = header.getOrDefault("X-Amz-Date")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Date", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Security-Token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Security-Token", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Content-Sha256", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Algorithm")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Algorithm", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Signature")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Signature", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-SignedHeaders", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Credential")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Credential", valid_601064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_PutMethod_601052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601066, url, valid)

proc call*(call_601067: Call_PutMethod_601052; httpMethod: string; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## putMethod
  ## Add a method to an existing <a>Resource</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the new <a>Method</a> resource.
  var path_601068 = newJObject()
  var body_601069 = newJObject()
  add(path_601068, "http_method", newJString(httpMethod))
  if body != nil:
    body_601069 = body
  add(path_601068, "restapi_id", newJString(restapiId))
  add(path_601068, "resource_id", newJString(resourceId))
  result = call_601067.call(path_601068, nil, nil, nil, body_601069)

var putMethod* = Call_PutMethod_601052(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_601053,
                                    base: "/", url: url_PutMethod_601054,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_601070 = ref object of OpenApiRestCall_599352
proc url_TestInvokeMethod_601072(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeMethod_601071(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies a test invoke method request's HTTP method.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] Specifies a test invoke method request's resource ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601073 = path.getOrDefault("http_method")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "http_method", valid_601073
  var valid_601074 = path.getOrDefault("restapi_id")
  valid_601074 = validateParameter(valid_601074, JString, required = true,
                                 default = nil)
  if valid_601074 != nil:
    section.add "restapi_id", valid_601074
  var valid_601075 = path.getOrDefault("resource_id")
  valid_601075 = validateParameter(valid_601075, JString, required = true,
                                 default = nil)
  if valid_601075 != nil:
    section.add "resource_id", valid_601075
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
  var valid_601076 = header.getOrDefault("X-Amz-Date")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Date", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Security-Token")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Security-Token", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Content-Sha256", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Algorithm")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Algorithm", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Signature")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Signature", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-SignedHeaders", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Credential")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Credential", valid_601082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601084: Call_TestInvokeMethod_601070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_601084.validator(path, query, header, formData, body)
  let scheme = call_601084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601084.url(scheme.get, call_601084.host, call_601084.base,
                         call_601084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601084, url, valid)

proc call*(call_601085: Call_TestInvokeMethod_601070; httpMethod: string;
          body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## testInvokeMethod
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a test invoke method request's HTTP method.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a test invoke method request's resource ID.
  var path_601086 = newJObject()
  var body_601087 = newJObject()
  add(path_601086, "http_method", newJString(httpMethod))
  if body != nil:
    body_601087 = body
  add(path_601086, "restapi_id", newJString(restapiId))
  add(path_601086, "resource_id", newJString(resourceId))
  result = call_601085.call(path_601086, nil, nil, nil, body_601087)

var testInvokeMethod* = Call_TestInvokeMethod_601070(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_601071, base: "/",
    url: url_TestInvokeMethod_601072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_601036 = ref object of OpenApiRestCall_599352
proc url_GetMethod_601038(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMethod_601037(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Describe an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] Specifies the method request's HTTP method type.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601039 = path.getOrDefault("http_method")
  valid_601039 = validateParameter(valid_601039, JString, required = true,
                                 default = nil)
  if valid_601039 != nil:
    section.add "http_method", valid_601039
  var valid_601040 = path.getOrDefault("restapi_id")
  valid_601040 = validateParameter(valid_601040, JString, required = true,
                                 default = nil)
  if valid_601040 != nil:
    section.add "restapi_id", valid_601040
  var valid_601041 = path.getOrDefault("resource_id")
  valid_601041 = validateParameter(valid_601041, JString, required = true,
                                 default = nil)
  if valid_601041 != nil:
    section.add "resource_id", valid_601041
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
  var valid_601042 = header.getOrDefault("X-Amz-Date")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Date", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Security-Token")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Security-Token", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Content-Sha256", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Algorithm")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Algorithm", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Signature")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Signature", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-SignedHeaders", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Credential")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Credential", valid_601048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_GetMethod_601036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601049, url, valid)

proc call*(call_601050: Call_GetMethod_601036; httpMethod: string; restapiId: string;
          resourceId: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_601051 = newJObject()
  add(path_601051, "http_method", newJString(httpMethod))
  add(path_601051, "restapi_id", newJString(restapiId))
  add(path_601051, "resource_id", newJString(resourceId))
  result = call_601050.call(path_601051, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_601036(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_601037,
                                    base: "/", url: url_GetMethod_601038,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_601104 = ref object of OpenApiRestCall_599352
proc url_UpdateMethod_601106(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethod_601105(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601107 = path.getOrDefault("http_method")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = nil)
  if valid_601107 != nil:
    section.add "http_method", valid_601107
  var valid_601108 = path.getOrDefault("restapi_id")
  valid_601108 = validateParameter(valid_601108, JString, required = true,
                                 default = nil)
  if valid_601108 != nil:
    section.add "restapi_id", valid_601108
  var valid_601109 = path.getOrDefault("resource_id")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = nil)
  if valid_601109 != nil:
    section.add "resource_id", valid_601109
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
  var valid_601110 = header.getOrDefault("X-Amz-Date")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Date", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Security-Token")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Security-Token", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Content-Sha256", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Algorithm")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Algorithm", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Signature")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Signature", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-SignedHeaders", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Credential")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Credential", valid_601116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601118: Call_UpdateMethod_601104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_601118.validator(path, query, header, formData, body)
  let scheme = call_601118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601118.url(scheme.get, call_601118.host, call_601118.base,
                         call_601118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601118, url, valid)

proc call*(call_601119: Call_UpdateMethod_601104; httpMethod: string; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateMethod
  ## Updates an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_601120 = newJObject()
  var body_601121 = newJObject()
  add(path_601120, "http_method", newJString(httpMethod))
  if body != nil:
    body_601121 = body
  add(path_601120, "restapi_id", newJString(restapiId))
  add(path_601120, "resource_id", newJString(resourceId))
  result = call_601119.call(path_601120, nil, nil, nil, body_601121)

var updateMethod* = Call_UpdateMethod_601104(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_601105, base: "/", url: url_UpdateMethod_601106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_601088 = ref object of OpenApiRestCall_599352
proc url_DeleteMethod_601090(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethod_601089(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601091 = path.getOrDefault("http_method")
  valid_601091 = validateParameter(valid_601091, JString, required = true,
                                 default = nil)
  if valid_601091 != nil:
    section.add "http_method", valid_601091
  var valid_601092 = path.getOrDefault("restapi_id")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = nil)
  if valid_601092 != nil:
    section.add "restapi_id", valid_601092
  var valid_601093 = path.getOrDefault("resource_id")
  valid_601093 = validateParameter(valid_601093, JString, required = true,
                                 default = nil)
  if valid_601093 != nil:
    section.add "resource_id", valid_601093
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
  var valid_601094 = header.getOrDefault("X-Amz-Date")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Date", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Security-Token")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Security-Token", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Content-Sha256", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Algorithm")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Algorithm", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Signature")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Signature", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-SignedHeaders", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Credential")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Credential", valid_601100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601101: Call_DeleteMethod_601088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_601101.validator(path, query, header, formData, body)
  let scheme = call_601101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601101.url(scheme.get, call_601101.host, call_601101.base,
                         call_601101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601101, url, valid)

proc call*(call_601102: Call_DeleteMethod_601088; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_601103 = newJObject()
  add(path_601103, "http_method", newJString(httpMethod))
  add(path_601103, "restapi_id", newJString(restapiId))
  add(path_601103, "resource_id", newJString(resourceId))
  result = call_601102.call(path_601103, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_601088(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_601089, base: "/", url: url_DeleteMethod_601090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_601139 = ref object of OpenApiRestCall_599352
proc url_PutMethodResponse_601141(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethodResponse_601140(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601142 = path.getOrDefault("http_method")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = nil)
  if valid_601142 != nil:
    section.add "http_method", valid_601142
  var valid_601143 = path.getOrDefault("status_code")
  valid_601143 = validateParameter(valid_601143, JString, required = true,
                                 default = nil)
  if valid_601143 != nil:
    section.add "status_code", valid_601143
  var valid_601144 = path.getOrDefault("restapi_id")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = nil)
  if valid_601144 != nil:
    section.add "restapi_id", valid_601144
  var valid_601145 = path.getOrDefault("resource_id")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = nil)
  if valid_601145 != nil:
    section.add "resource_id", valid_601145
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
  var valid_601146 = header.getOrDefault("X-Amz-Date")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Date", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Security-Token")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Security-Token", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_PutMethodResponse_601139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601154, url, valid)

proc call*(call_601155: Call_PutMethodResponse_601139; httpMethod: string;
          statusCode: string; body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## putMethodResponse
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_601156 = newJObject()
  var body_601157 = newJObject()
  add(path_601156, "http_method", newJString(httpMethod))
  add(path_601156, "status_code", newJString(statusCode))
  if body != nil:
    body_601157 = body
  add(path_601156, "restapi_id", newJString(restapiId))
  add(path_601156, "resource_id", newJString(resourceId))
  result = call_601155.call(path_601156, nil, nil, nil, body_601157)

var putMethodResponse* = Call_PutMethodResponse_601139(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_601140, base: "/",
    url: url_PutMethodResponse_601141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_601122 = ref object of OpenApiRestCall_599352
proc url_GetMethodResponse_601124(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethodResponse_601123(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601125 = path.getOrDefault("http_method")
  valid_601125 = validateParameter(valid_601125, JString, required = true,
                                 default = nil)
  if valid_601125 != nil:
    section.add "http_method", valid_601125
  var valid_601126 = path.getOrDefault("status_code")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = nil)
  if valid_601126 != nil:
    section.add "status_code", valid_601126
  var valid_601127 = path.getOrDefault("restapi_id")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "restapi_id", valid_601127
  var valid_601128 = path.getOrDefault("resource_id")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = nil)
  if valid_601128 != nil:
    section.add "resource_id", valid_601128
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
  var valid_601129 = header.getOrDefault("X-Amz-Date")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Date", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Security-Token")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Security-Token", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Content-Sha256", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Algorithm")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Algorithm", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Signature")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Signature", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-SignedHeaders", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Credential")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Credential", valid_601135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601136: Call_GetMethodResponse_601122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_601136.validator(path, query, header, formData, body)
  let scheme = call_601136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601136.url(scheme.get, call_601136.host, call_601136.base,
                         call_601136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601136, url, valid)

proc call*(call_601137: Call_GetMethodResponse_601122; httpMethod: string;
          statusCode: string; restapiId: string; resourceId: string): Recallable =
  ## getMethodResponse
  ## Describes a <a>MethodResponse</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  var path_601138 = newJObject()
  add(path_601138, "http_method", newJString(httpMethod))
  add(path_601138, "status_code", newJString(statusCode))
  add(path_601138, "restapi_id", newJString(restapiId))
  add(path_601138, "resource_id", newJString(resourceId))
  result = call_601137.call(path_601138, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_601122(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_601123, base: "/",
    url: url_GetMethodResponse_601124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_601175 = ref object of OpenApiRestCall_599352
proc url_UpdateMethodResponse_601177(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethodResponse_601176(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601178 = path.getOrDefault("http_method")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = nil)
  if valid_601178 != nil:
    section.add "http_method", valid_601178
  var valid_601179 = path.getOrDefault("status_code")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "status_code", valid_601179
  var valid_601180 = path.getOrDefault("restapi_id")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = nil)
  if valid_601180 != nil:
    section.add "restapi_id", valid_601180
  var valid_601181 = path.getOrDefault("resource_id")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = nil)
  if valid_601181 != nil:
    section.add "resource_id", valid_601181
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
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_UpdateMethodResponse_601175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601190, url, valid)

proc call*(call_601191: Call_UpdateMethodResponse_601175; httpMethod: string;
          statusCode: string; body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## updateMethodResponse
  ## Updates an existing <a>MethodResponse</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  var path_601192 = newJObject()
  var body_601193 = newJObject()
  add(path_601192, "http_method", newJString(httpMethod))
  add(path_601192, "status_code", newJString(statusCode))
  if body != nil:
    body_601193 = body
  add(path_601192, "restapi_id", newJString(restapiId))
  add(path_601192, "resource_id", newJString(resourceId))
  result = call_601191.call(path_601192, nil, nil, nil, body_601193)

var updateMethodResponse* = Call_UpdateMethodResponse_601175(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_601176, base: "/",
    url: url_UpdateMethodResponse_601177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_601158 = ref object of OpenApiRestCall_599352
proc url_DeleteMethodResponse_601160(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethodResponse_601159(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   http_method: JString (required)
  ##              : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   status_code: JString (required)
  ##              : The status code.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resource_id: JString (required)
  ##              : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `http_method` field"
  var valid_601161 = path.getOrDefault("http_method")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "http_method", valid_601161
  var valid_601162 = path.getOrDefault("status_code")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = nil)
  if valid_601162 != nil:
    section.add "status_code", valid_601162
  var valid_601163 = path.getOrDefault("restapi_id")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "restapi_id", valid_601163
  var valid_601164 = path.getOrDefault("resource_id")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "resource_id", valid_601164
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
  var valid_601165 = header.getOrDefault("X-Amz-Date")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Date", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Security-Token")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Security-Token", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Content-Sha256", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Algorithm")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Algorithm", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Signature")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Signature", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-SignedHeaders", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Credential")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Credential", valid_601171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601172: Call_DeleteMethodResponse_601158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_601172.validator(path, query, header, formData, body)
  let scheme = call_601172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601172.url(scheme.get, call_601172.host, call_601172.base,
                         call_601172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601172, url, valid)

proc call*(call_601173: Call_DeleteMethodResponse_601158; httpMethod: string;
          statusCode: string; restapiId: string; resourceId: string): Recallable =
  ## deleteMethodResponse
  ## Deletes an existing <a>MethodResponse</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   statusCode: string (required)
  ##             : The status code.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>MethodResponse</a> resource.
  var path_601174 = newJObject()
  add(path_601174, "http_method", newJString(httpMethod))
  add(path_601174, "status_code", newJString(statusCode))
  add(path_601174, "restapi_id", newJString(restapiId))
  add(path_601174, "resource_id", newJString(resourceId))
  result = call_601173.call(path_601174, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_601158(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_601159, base: "/",
    url: url_DeleteMethodResponse_601160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_601194 = ref object of OpenApiRestCall_599352
proc url_GetModel_601196(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_601195(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601197 = path.getOrDefault("model_name")
  valid_601197 = validateParameter(valid_601197, JString, required = true,
                                 default = nil)
  if valid_601197 != nil:
    section.add "model_name", valid_601197
  var valid_601198 = path.getOrDefault("restapi_id")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = nil)
  if valid_601198 != nil:
    section.add "restapi_id", valid_601198
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_601199 = query.getOrDefault("flatten")
  valid_601199 = validateParameter(valid_601199, JBool, required = false, default = nil)
  if valid_601199 != nil:
    section.add "flatten", valid_601199
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
  var valid_601200 = header.getOrDefault("X-Amz-Date")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Date", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Security-Token")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Security-Token", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Content-Sha256", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Algorithm")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Algorithm", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Signature")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Signature", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-SignedHeaders", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Credential")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Credential", valid_601206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601207: Call_GetModel_601194; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_601207.validator(path, query, header, formData, body)
  let scheme = call_601207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601207.url(scheme.get, call_601207.host, call_601207.base,
                         call_601207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601207, url, valid)

proc call*(call_601208: Call_GetModel_601194; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_601209 = newJObject()
  var query_601210 = newJObject()
  add(query_601210, "flatten", newJBool(flatten))
  add(path_601209, "model_name", newJString(modelName))
  add(path_601209, "restapi_id", newJString(restapiId))
  result = call_601208.call(path_601209, query_601210, nil, nil, nil)

var getModel* = Call_GetModel_601194(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_601195, base: "/",
                                  url: url_GetModel_601196,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_601226 = ref object of OpenApiRestCall_599352
proc url_UpdateModel_601228(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_601227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601229 = path.getOrDefault("model_name")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = nil)
  if valid_601229 != nil:
    section.add "model_name", valid_601229
  var valid_601230 = path.getOrDefault("restapi_id")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = nil)
  if valid_601230 != nil:
    section.add "restapi_id", valid_601230
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
  var valid_601231 = header.getOrDefault("X-Amz-Date")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Date", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Security-Token")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Security-Token", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601239: Call_UpdateModel_601226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_601239.validator(path, query, header, formData, body)
  let scheme = call_601239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601239.url(scheme.get, call_601239.host, call_601239.base,
                         call_601239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601239, url, valid)

proc call*(call_601240: Call_UpdateModel_601226; modelName: string; body: JsonNode;
          restapiId: string): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601241 = newJObject()
  var body_601242 = newJObject()
  add(path_601241, "model_name", newJString(modelName))
  if body != nil:
    body_601242 = body
  add(path_601241, "restapi_id", newJString(restapiId))
  result = call_601240.call(path_601241, nil, nil, nil, body_601242)

var updateModel* = Call_UpdateModel_601226(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_601227,
                                        base: "/", url: url_UpdateModel_601228,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_601211 = ref object of OpenApiRestCall_599352
proc url_DeleteModel_601213(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_601212(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601214 = path.getOrDefault("model_name")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = nil)
  if valid_601214 != nil:
    section.add "model_name", valid_601214
  var valid_601215 = path.getOrDefault("restapi_id")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "restapi_id", valid_601215
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
  var valid_601216 = header.getOrDefault("X-Amz-Date")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Date", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Security-Token")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Security-Token", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Content-Sha256", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Algorithm")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Algorithm", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Signature")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Signature", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-SignedHeaders", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Credential")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Credential", valid_601222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601223: Call_DeleteModel_601211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_601223.validator(path, query, header, formData, body)
  let scheme = call_601223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601223.url(scheme.get, call_601223.host, call_601223.base,
                         call_601223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601223, url, valid)

proc call*(call_601224: Call_DeleteModel_601211; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601225 = newJObject()
  add(path_601225, "model_name", newJString(modelName))
  add(path_601225, "restapi_id", newJString(restapiId))
  result = call_601224.call(path_601225, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_601211(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_601212,
                                        base: "/", url: url_DeleteModel_601213,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_601243 = ref object of OpenApiRestCall_599352
proc url_GetRequestValidator_601245(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidator_601244(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   requestvalidator_id: JString (required)
  ##                      : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `requestvalidator_id` field"
  var valid_601246 = path.getOrDefault("requestvalidator_id")
  valid_601246 = validateParameter(valid_601246, JString, required = true,
                                 default = nil)
  if valid_601246 != nil:
    section.add "requestvalidator_id", valid_601246
  var valid_601247 = path.getOrDefault("restapi_id")
  valid_601247 = validateParameter(valid_601247, JString, required = true,
                                 default = nil)
  if valid_601247 != nil:
    section.add "restapi_id", valid_601247
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
  var valid_601248 = header.getOrDefault("X-Amz-Date")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Date", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Security-Token")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Security-Token", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Content-Sha256", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Algorithm")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Algorithm", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Signature")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Signature", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-SignedHeaders", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Credential")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Credential", valid_601254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601255: Call_GetRequestValidator_601243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_601255.validator(path, query, header, formData, body)
  let scheme = call_601255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601255.url(scheme.get, call_601255.host, call_601255.base,
                         call_601255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601255, url, valid)

proc call*(call_601256: Call_GetRequestValidator_601243;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601257 = newJObject()
  add(path_601257, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_601257, "restapi_id", newJString(restapiId))
  result = call_601256.call(path_601257, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_601243(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_601244, base: "/",
    url: url_GetRequestValidator_601245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_601273 = ref object of OpenApiRestCall_599352
proc url_UpdateRequestValidator_601275(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRequestValidator_601274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   requestvalidator_id: JString (required)
  ##                      : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `requestvalidator_id` field"
  var valid_601276 = path.getOrDefault("requestvalidator_id")
  valid_601276 = validateParameter(valid_601276, JString, required = true,
                                 default = nil)
  if valid_601276 != nil:
    section.add "requestvalidator_id", valid_601276
  var valid_601277 = path.getOrDefault("restapi_id")
  valid_601277 = validateParameter(valid_601277, JString, required = true,
                                 default = nil)
  if valid_601277 != nil:
    section.add "restapi_id", valid_601277
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
  var valid_601278 = header.getOrDefault("X-Amz-Date")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Date", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Security-Token")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Security-Token", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Content-Sha256", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Algorithm")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Algorithm", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Signature")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Signature", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-SignedHeaders", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Credential")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Credential", valid_601284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601286: Call_UpdateRequestValidator_601273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_601286.validator(path, query, header, formData, body)
  let scheme = call_601286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601286.url(scheme.get, call_601286.host, call_601286.base,
                         call_601286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601286, url, valid)

proc call*(call_601287: Call_UpdateRequestValidator_601273;
          requestvalidatorId: string; body: JsonNode; restapiId: string): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601288 = newJObject()
  var body_601289 = newJObject()
  add(path_601288, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_601289 = body
  add(path_601288, "restapi_id", newJString(restapiId))
  result = call_601287.call(path_601288, nil, nil, nil, body_601289)

var updateRequestValidator* = Call_UpdateRequestValidator_601273(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_601274, base: "/",
    url: url_UpdateRequestValidator_601275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_601258 = ref object of OpenApiRestCall_599352
proc url_DeleteRequestValidator_601260(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRequestValidator_601259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   requestvalidator_id: JString (required)
  ##                      : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `requestvalidator_id` field"
  var valid_601261 = path.getOrDefault("requestvalidator_id")
  valid_601261 = validateParameter(valid_601261, JString, required = true,
                                 default = nil)
  if valid_601261 != nil:
    section.add "requestvalidator_id", valid_601261
  var valid_601262 = path.getOrDefault("restapi_id")
  valid_601262 = validateParameter(valid_601262, JString, required = true,
                                 default = nil)
  if valid_601262 != nil:
    section.add "restapi_id", valid_601262
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
  var valid_601263 = header.getOrDefault("X-Amz-Date")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Date", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Security-Token")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Security-Token", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Content-Sha256", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Algorithm")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Algorithm", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Signature")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Signature", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-SignedHeaders", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Credential")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Credential", valid_601269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_DeleteRequestValidator_601258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601270, url, valid)

proc call*(call_601271: Call_DeleteRequestValidator_601258;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601272 = newJObject()
  add(path_601272, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_601272, "restapi_id", newJString(restapiId))
  result = call_601271.call(path_601272, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_601258(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_601259, base: "/",
    url: url_DeleteRequestValidator_601260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_601290 = ref object of OpenApiRestCall_599352
proc url_GetResource_601292(protocol: Scheme; host: string; base: string;
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

proc validate_GetResource_601291(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601293 = path.getOrDefault("restapi_id")
  valid_601293 = validateParameter(valid_601293, JString, required = true,
                                 default = nil)
  if valid_601293 != nil:
    section.add "restapi_id", valid_601293
  var valid_601294 = path.getOrDefault("resource_id")
  valid_601294 = validateParameter(valid_601294, JString, required = true,
                                 default = nil)
  if valid_601294 != nil:
    section.add "resource_id", valid_601294
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_601295 = query.getOrDefault("embed")
  valid_601295 = validateParameter(valid_601295, JArray, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "embed", valid_601295
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
  var valid_601296 = header.getOrDefault("X-Amz-Date")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Date", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Security-Token")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Security-Token", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601303: Call_GetResource_601290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_601303.validator(path, query, header, formData, body)
  let scheme = call_601303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601303.url(scheme.get, call_601303.host, call_601303.base,
                         call_601303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601303, url, valid)

proc call*(call_601304: Call_GetResource_601290; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_601305 = newJObject()
  var query_601306 = newJObject()
  if embed != nil:
    query_601306.add "embed", embed
  add(path_601305, "restapi_id", newJString(restapiId))
  add(path_601305, "resource_id", newJString(resourceId))
  result = call_601304.call(path_601305, query_601306, nil, nil, nil)

var getResource* = Call_GetResource_601290(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_601291,
                                        base: "/", url: url_GetResource_601292,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_601322 = ref object of OpenApiRestCall_599352
proc url_UpdateResource_601324(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResource_601323(path: JsonNode; query: JsonNode;
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
  var valid_601325 = path.getOrDefault("restapi_id")
  valid_601325 = validateParameter(valid_601325, JString, required = true,
                                 default = nil)
  if valid_601325 != nil:
    section.add "restapi_id", valid_601325
  var valid_601326 = path.getOrDefault("resource_id")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = nil)
  if valid_601326 != nil:
    section.add "resource_id", valid_601326
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
  var valid_601327 = header.getOrDefault("X-Amz-Date")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Date", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Security-Token")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Security-Token", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Content-Sha256", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Algorithm")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Algorithm", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Signature")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Signature", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-SignedHeaders", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Credential")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Credential", valid_601333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601335: Call_UpdateResource_601322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_601335.validator(path, query, header, formData, body)
  let scheme = call_601335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601335.url(scheme.get, call_601335.host, call_601335.base,
                         call_601335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601335, url, valid)

proc call*(call_601336: Call_UpdateResource_601322; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_601337 = newJObject()
  var body_601338 = newJObject()
  if body != nil:
    body_601338 = body
  add(path_601337, "restapi_id", newJString(restapiId))
  add(path_601337, "resource_id", newJString(resourceId))
  result = call_601336.call(path_601337, nil, nil, nil, body_601338)

var updateResource* = Call_UpdateResource_601322(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_601323, base: "/", url: url_UpdateResource_601324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_601307 = ref object of OpenApiRestCall_599352
proc url_DeleteResource_601309(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResource_601308(path: JsonNode; query: JsonNode;
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
  var valid_601310 = path.getOrDefault("restapi_id")
  valid_601310 = validateParameter(valid_601310, JString, required = true,
                                 default = nil)
  if valid_601310 != nil:
    section.add "restapi_id", valid_601310
  var valid_601311 = path.getOrDefault("resource_id")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = nil)
  if valid_601311 != nil:
    section.add "resource_id", valid_601311
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
  var valid_601312 = header.getOrDefault("X-Amz-Date")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Date", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Security-Token")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Security-Token", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Content-Sha256", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Algorithm")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Algorithm", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Signature")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Signature", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-SignedHeaders", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Credential")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Credential", valid_601318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_DeleteResource_601307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601319, url, valid)

proc call*(call_601320: Call_DeleteResource_601307; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_601321 = newJObject()
  add(path_601321, "restapi_id", newJString(restapiId))
  add(path_601321, "resource_id", newJString(resourceId))
  result = call_601320.call(path_601321, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_601307(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_601308, base: "/", url: url_DeleteResource_601309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_601353 = ref object of OpenApiRestCall_599352
proc url_PutRestApi_601355(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutRestApi_601354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601356 = path.getOrDefault("restapi_id")
  valid_601356 = validateParameter(valid_601356, JString, required = true,
                                 default = nil)
  if valid_601356 != nil:
    section.add "restapi_id", valid_601356
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   mode: JString
  ##       : The <code>mode</code> query parameter to specify the update mode. Valid values are "merge" and "overwrite". By default, the update mode is "merge".
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   failonwarnings: JBool
  ##                 : A query parameter to indicate whether to rollback the API update (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_601357 = query.getOrDefault("parameters.0.value")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "parameters.0.value", valid_601357
  var valid_601358 = query.getOrDefault("parameters.2.value")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "parameters.2.value", valid_601358
  var valid_601359 = query.getOrDefault("parameters.1.key")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "parameters.1.key", valid_601359
  var valid_601360 = query.getOrDefault("mode")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = newJString("merge"))
  if valid_601360 != nil:
    section.add "mode", valid_601360
  var valid_601361 = query.getOrDefault("parameters.0.key")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "parameters.0.key", valid_601361
  var valid_601362 = query.getOrDefault("parameters.2.key")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "parameters.2.key", valid_601362
  var valid_601363 = query.getOrDefault("failonwarnings")
  valid_601363 = validateParameter(valid_601363, JBool, required = false, default = nil)
  if valid_601363 != nil:
    section.add "failonwarnings", valid_601363
  var valid_601364 = query.getOrDefault("parameters.1.value")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "parameters.1.value", valid_601364
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
  var valid_601365 = header.getOrDefault("X-Amz-Date")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Date", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Security-Token")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Security-Token", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Content-Sha256", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Algorithm")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Algorithm", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Signature")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Signature", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-SignedHeaders", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Credential")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Credential", valid_601371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601373: Call_PutRestApi_601353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_601373.validator(path, query, header, formData, body)
  let scheme = call_601373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601373.url(scheme.get, call_601373.host, call_601373.base,
                         call_601373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601373, url, valid)

proc call*(call_601374: Call_PutRestApi_601353; body: JsonNode; restapiId: string;
          parameters0Value: string = ""; parameters2Value: string = "";
          parameters1Key: string = ""; mode: string = "merge";
          parameters0Key: string = ""; parameters2Key: string = "";
          failonwarnings: bool = false; parameters1Value: string = ""): Recallable =
  ## putRestApi
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ##   parameters0Value: string
  ##   parameters2Value: string
  ##   parameters1Key: string
  ##   mode: string
  ##       : The <code>mode</code> query parameter to specify the update mode. Valid values are "merge" and "overwrite". By default, the update mode is "merge".
  ##   parameters0Key: string
  ##   parameters2Key: string
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback the API update (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   parameters1Value: string
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601375 = newJObject()
  var query_601376 = newJObject()
  var body_601377 = newJObject()
  add(query_601376, "parameters.0.value", newJString(parameters0Value))
  add(query_601376, "parameters.2.value", newJString(parameters2Value))
  add(query_601376, "parameters.1.key", newJString(parameters1Key))
  add(query_601376, "mode", newJString(mode))
  add(query_601376, "parameters.0.key", newJString(parameters0Key))
  add(query_601376, "parameters.2.key", newJString(parameters2Key))
  add(query_601376, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_601377 = body
  add(query_601376, "parameters.1.value", newJString(parameters1Value))
  add(path_601375, "restapi_id", newJString(restapiId))
  result = call_601374.call(path_601375, query_601376, nil, nil, body_601377)

var putRestApi* = Call_PutRestApi_601353(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_601354,
                                      base: "/", url: url_PutRestApi_601355,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_601339 = ref object of OpenApiRestCall_599352
proc url_GetRestApi_601341(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRestApi_601340(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601342 = path.getOrDefault("restapi_id")
  valid_601342 = validateParameter(valid_601342, JString, required = true,
                                 default = nil)
  if valid_601342 != nil:
    section.add "restapi_id", valid_601342
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
  var valid_601343 = header.getOrDefault("X-Amz-Date")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Date", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Security-Token")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Security-Token", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Content-Sha256", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Algorithm")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Algorithm", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Signature")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Signature", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-SignedHeaders", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Credential")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Credential", valid_601349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601350: Call_GetRestApi_601339; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_601350.validator(path, query, header, formData, body)
  let scheme = call_601350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601350.url(scheme.get, call_601350.host, call_601350.base,
                         call_601350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601350, url, valid)

proc call*(call_601351: Call_GetRestApi_601339; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601352 = newJObject()
  add(path_601352, "restapi_id", newJString(restapiId))
  result = call_601351.call(path_601352, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_601339(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_601340,
                                      base: "/", url: url_GetRestApi_601341,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_601392 = ref object of OpenApiRestCall_599352
proc url_UpdateRestApi_601394(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRestApi_601393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601395 = path.getOrDefault("restapi_id")
  valid_601395 = validateParameter(valid_601395, JString, required = true,
                                 default = nil)
  if valid_601395 != nil:
    section.add "restapi_id", valid_601395
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
  var valid_601396 = header.getOrDefault("X-Amz-Date")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Date", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Security-Token")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Security-Token", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Content-Sha256", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Algorithm")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Algorithm", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Signature")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Signature", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-SignedHeaders", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Credential")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Credential", valid_601402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601404: Call_UpdateRestApi_601392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_601404.validator(path, query, header, formData, body)
  let scheme = call_601404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601404.url(scheme.get, call_601404.host, call_601404.base,
                         call_601404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601404, url, valid)

proc call*(call_601405: Call_UpdateRestApi_601392; body: JsonNode; restapiId: string): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601406 = newJObject()
  var body_601407 = newJObject()
  if body != nil:
    body_601407 = body
  add(path_601406, "restapi_id", newJString(restapiId))
  result = call_601405.call(path_601406, nil, nil, nil, body_601407)

var updateRestApi* = Call_UpdateRestApi_601392(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_601393,
    base: "/", url: url_UpdateRestApi_601394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_601378 = ref object of OpenApiRestCall_599352
proc url_DeleteRestApi_601380(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRestApi_601379(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601381 = path.getOrDefault("restapi_id")
  valid_601381 = validateParameter(valid_601381, JString, required = true,
                                 default = nil)
  if valid_601381 != nil:
    section.add "restapi_id", valid_601381
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
  var valid_601382 = header.getOrDefault("X-Amz-Date")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Date", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Security-Token")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Security-Token", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Content-Sha256", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Algorithm")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Algorithm", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Signature")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Signature", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-SignedHeaders", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Credential")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Credential", valid_601388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601389: Call_DeleteRestApi_601378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_601389.validator(path, query, header, formData, body)
  let scheme = call_601389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601389.url(scheme.get, call_601389.host, call_601389.base,
                         call_601389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601389, url, valid)

proc call*(call_601390: Call_DeleteRestApi_601378; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601391 = newJObject()
  add(path_601391, "restapi_id", newJString(restapiId))
  result = call_601390.call(path_601391, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_601378(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_601379,
    base: "/", url: url_DeleteRestApi_601380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_601408 = ref object of OpenApiRestCall_599352
proc url_GetStage_601410(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_601409(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `stage_name` field"
  var valid_601411 = path.getOrDefault("stage_name")
  valid_601411 = validateParameter(valid_601411, JString, required = true,
                                 default = nil)
  if valid_601411 != nil:
    section.add "stage_name", valid_601411
  var valid_601412 = path.getOrDefault("restapi_id")
  valid_601412 = validateParameter(valid_601412, JString, required = true,
                                 default = nil)
  if valid_601412 != nil:
    section.add "restapi_id", valid_601412
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
  var valid_601413 = header.getOrDefault("X-Amz-Date")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Date", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Security-Token")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Security-Token", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Content-Sha256", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Algorithm")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Algorithm", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Signature")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Signature", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-SignedHeaders", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Credential")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Credential", valid_601419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601420: Call_GetStage_601408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_601420.validator(path, query, header, formData, body)
  let scheme = call_601420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601420.url(scheme.get, call_601420.host, call_601420.base,
                         call_601420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601420, url, valid)

proc call*(call_601421: Call_GetStage_601408; stageName: string; restapiId: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601422 = newJObject()
  add(path_601422, "stage_name", newJString(stageName))
  add(path_601422, "restapi_id", newJString(restapiId))
  result = call_601421.call(path_601422, nil, nil, nil, nil)

var getStage* = Call_GetStage_601408(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_601409, base: "/",
                                  url: url_GetStage_601410,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_601438 = ref object of OpenApiRestCall_599352
proc url_UpdateStage_601440(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_601439(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `stage_name` field"
  var valid_601441 = path.getOrDefault("stage_name")
  valid_601441 = validateParameter(valid_601441, JString, required = true,
                                 default = nil)
  if valid_601441 != nil:
    section.add "stage_name", valid_601441
  var valid_601442 = path.getOrDefault("restapi_id")
  valid_601442 = validateParameter(valid_601442, JString, required = true,
                                 default = nil)
  if valid_601442 != nil:
    section.add "restapi_id", valid_601442
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
  var valid_601443 = header.getOrDefault("X-Amz-Date")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Date", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Security-Token")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Security-Token", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Content-Sha256", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Algorithm")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Algorithm", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Signature")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Signature", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-SignedHeaders", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Credential")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Credential", valid_601449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601451: Call_UpdateStage_601438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_601451.validator(path, query, header, formData, body)
  let scheme = call_601451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601451.url(scheme.get, call_601451.host, call_601451.base,
                         call_601451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601451, url, valid)

proc call*(call_601452: Call_UpdateStage_601438; body: JsonNode; stageName: string;
          restapiId: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601453 = newJObject()
  var body_601454 = newJObject()
  if body != nil:
    body_601454 = body
  add(path_601453, "stage_name", newJString(stageName))
  add(path_601453, "restapi_id", newJString(restapiId))
  result = call_601452.call(path_601453, nil, nil, nil, body_601454)

var updateStage* = Call_UpdateStage_601438(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_601439,
                                        base: "/", url: url_UpdateStage_601440,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_601423 = ref object of OpenApiRestCall_599352
proc url_DeleteStage_601425(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_601424(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <a>Stage</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `stage_name` field"
  var valid_601426 = path.getOrDefault("stage_name")
  valid_601426 = validateParameter(valid_601426, JString, required = true,
                                 default = nil)
  if valid_601426 != nil:
    section.add "stage_name", valid_601426
  var valid_601427 = path.getOrDefault("restapi_id")
  valid_601427 = validateParameter(valid_601427, JString, required = true,
                                 default = nil)
  if valid_601427 != nil:
    section.add "restapi_id", valid_601427
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
  var valid_601428 = header.getOrDefault("X-Amz-Date")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Date", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Security-Token")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Security-Token", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Content-Sha256", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Algorithm")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Algorithm", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Signature")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Signature", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-SignedHeaders", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Credential")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Credential", valid_601434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601435: Call_DeleteStage_601423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_601435.validator(path, query, header, formData, body)
  let scheme = call_601435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601435.url(scheme.get, call_601435.host, call_601435.base,
                         call_601435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601435, url, valid)

proc call*(call_601436: Call_DeleteStage_601423; stageName: string; restapiId: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601437 = newJObject()
  add(path_601437, "stage_name", newJString(stageName))
  add(path_601437, "restapi_id", newJString(restapiId))
  result = call_601436.call(path_601437, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_601423(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_601424,
                                        base: "/", url: url_DeleteStage_601425,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_601455 = ref object of OpenApiRestCall_599352
proc url_GetUsagePlan_601457(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlan_601456(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601458 = path.getOrDefault("usageplanId")
  valid_601458 = validateParameter(valid_601458, JString, required = true,
                                 default = nil)
  if valid_601458 != nil:
    section.add "usageplanId", valid_601458
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
  var valid_601459 = header.getOrDefault("X-Amz-Date")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Date", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Security-Token")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Security-Token", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Content-Sha256", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Algorithm")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Algorithm", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Signature")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Signature", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-SignedHeaders", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Credential")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Credential", valid_601465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601466: Call_GetUsagePlan_601455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_601466.validator(path, query, header, formData, body)
  let scheme = call_601466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601466.url(scheme.get, call_601466.host, call_601466.base,
                         call_601466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601466, url, valid)

proc call*(call_601467: Call_GetUsagePlan_601455; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_601468 = newJObject()
  add(path_601468, "usageplanId", newJString(usageplanId))
  result = call_601467.call(path_601468, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_601455(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_601456,
    base: "/", url: url_GetUsagePlan_601457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_601483 = ref object of OpenApiRestCall_599352
proc url_UpdateUsagePlan_601485(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsagePlan_601484(path: JsonNode; query: JsonNode;
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
  var valid_601486 = path.getOrDefault("usageplanId")
  valid_601486 = validateParameter(valid_601486, JString, required = true,
                                 default = nil)
  if valid_601486 != nil:
    section.add "usageplanId", valid_601486
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
  var valid_601487 = header.getOrDefault("X-Amz-Date")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Date", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Security-Token")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Security-Token", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Content-Sha256", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Algorithm")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Algorithm", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Signature")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Signature", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-SignedHeaders", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Credential")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Credential", valid_601493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601495: Call_UpdateUsagePlan_601483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_601495.validator(path, query, header, formData, body)
  let scheme = call_601495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601495.url(scheme.get, call_601495.host, call_601495.base,
                         call_601495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601495, url, valid)

proc call*(call_601496: Call_UpdateUsagePlan_601483; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_601497 = newJObject()
  var body_601498 = newJObject()
  add(path_601497, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_601498 = body
  result = call_601496.call(path_601497, nil, nil, nil, body_601498)

var updateUsagePlan* = Call_UpdateUsagePlan_601483(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_601484,
    base: "/", url: url_UpdateUsagePlan_601485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_601469 = ref object of OpenApiRestCall_599352
proc url_DeleteUsagePlan_601471(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlan_601470(path: JsonNode; query: JsonNode;
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
  var valid_601472 = path.getOrDefault("usageplanId")
  valid_601472 = validateParameter(valid_601472, JString, required = true,
                                 default = nil)
  if valid_601472 != nil:
    section.add "usageplanId", valid_601472
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
  var valid_601473 = header.getOrDefault("X-Amz-Date")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Date", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Security-Token")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Security-Token", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Content-Sha256", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Algorithm")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Algorithm", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Signature")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Signature", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-SignedHeaders", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Credential")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Credential", valid_601479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601480: Call_DeleteUsagePlan_601469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_601480.validator(path, query, header, formData, body)
  let scheme = call_601480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601480.url(scheme.get, call_601480.host, call_601480.base,
                         call_601480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601480, url, valid)

proc call*(call_601481: Call_DeleteUsagePlan_601469; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_601482 = newJObject()
  add(path_601482, "usageplanId", newJString(usageplanId))
  result = call_601481.call(path_601482, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_601469(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_601470,
    base: "/", url: url_DeleteUsagePlan_601471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_601499 = ref object of OpenApiRestCall_599352
proc url_GetUsagePlanKey_601501(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKey_601500(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a usage plan key of a given key identifier.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   keyId: JString (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `keyId` field"
  var valid_601502 = path.getOrDefault("keyId")
  valid_601502 = validateParameter(valid_601502, JString, required = true,
                                 default = nil)
  if valid_601502 != nil:
    section.add "keyId", valid_601502
  var valid_601503 = path.getOrDefault("usageplanId")
  valid_601503 = validateParameter(valid_601503, JString, required = true,
                                 default = nil)
  if valid_601503 != nil:
    section.add "usageplanId", valid_601503
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
  var valid_601504 = header.getOrDefault("X-Amz-Date")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Date", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Security-Token")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Security-Token", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Content-Sha256", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Algorithm")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Algorithm", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Signature")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Signature", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-SignedHeaders", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Credential")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Credential", valid_601510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601511: Call_GetUsagePlanKey_601499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_601511.validator(path, query, header, formData, body)
  let scheme = call_601511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601511.url(scheme.get, call_601511.host, call_601511.base,
                         call_601511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601511, url, valid)

proc call*(call_601512: Call_GetUsagePlanKey_601499; keyId: string;
          usageplanId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_601513 = newJObject()
  add(path_601513, "keyId", newJString(keyId))
  add(path_601513, "usageplanId", newJString(usageplanId))
  result = call_601512.call(path_601513, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_601499(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_601500, base: "/", url: url_GetUsagePlanKey_601501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_601514 = ref object of OpenApiRestCall_599352
proc url_DeleteUsagePlanKey_601516(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlanKey_601515(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   keyId: JString (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `keyId` field"
  var valid_601517 = path.getOrDefault("keyId")
  valid_601517 = validateParameter(valid_601517, JString, required = true,
                                 default = nil)
  if valid_601517 != nil:
    section.add "keyId", valid_601517
  var valid_601518 = path.getOrDefault("usageplanId")
  valid_601518 = validateParameter(valid_601518, JString, required = true,
                                 default = nil)
  if valid_601518 != nil:
    section.add "usageplanId", valid_601518
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
  var valid_601519 = header.getOrDefault("X-Amz-Date")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Date", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Security-Token")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Security-Token", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Content-Sha256", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Algorithm")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Algorithm", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Signature")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Signature", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-SignedHeaders", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Credential")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Credential", valid_601525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601526: Call_DeleteUsagePlanKey_601514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_601526.validator(path, query, header, formData, body)
  let scheme = call_601526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601526.url(scheme.get, call_601526.host, call_601526.base,
                         call_601526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601526, url, valid)

proc call*(call_601527: Call_DeleteUsagePlanKey_601514; keyId: string;
          usageplanId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  var path_601528 = newJObject()
  add(path_601528, "keyId", newJString(keyId))
  add(path_601528, "usageplanId", newJString(usageplanId))
  result = call_601527.call(path_601528, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_601514(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_601515, base: "/",
    url: url_DeleteUsagePlanKey_601516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_601529 = ref object of OpenApiRestCall_599352
proc url_GetVpcLink_601531(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetVpcLink_601530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601532 = path.getOrDefault("vpclink_id")
  valid_601532 = validateParameter(valid_601532, JString, required = true,
                                 default = nil)
  if valid_601532 != nil:
    section.add "vpclink_id", valid_601532
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
  var valid_601533 = header.getOrDefault("X-Amz-Date")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Date", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Security-Token")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Security-Token", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Content-Sha256", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Algorithm")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Algorithm", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Signature")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Signature", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-SignedHeaders", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Credential")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Credential", valid_601539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601540: Call_GetVpcLink_601529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_601540.validator(path, query, header, formData, body)
  let scheme = call_601540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601540.url(scheme.get, call_601540.host, call_601540.base,
                         call_601540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601540, url, valid)

proc call*(call_601541: Call_GetVpcLink_601529; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_601542 = newJObject()
  add(path_601542, "vpclink_id", newJString(vpclinkId))
  result = call_601541.call(path_601542, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_601529(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_601530,
                                      base: "/", url: url_GetVpcLink_601531,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_601557 = ref object of OpenApiRestCall_599352
proc url_UpdateVpcLink_601559(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVpcLink_601558(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601560 = path.getOrDefault("vpclink_id")
  valid_601560 = validateParameter(valid_601560, JString, required = true,
                                 default = nil)
  if valid_601560 != nil:
    section.add "vpclink_id", valid_601560
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
  var valid_601561 = header.getOrDefault("X-Amz-Date")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Date", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Security-Token")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Security-Token", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Content-Sha256", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Algorithm")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Algorithm", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Signature")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Signature", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-SignedHeaders", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Credential")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Credential", valid_601567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601569: Call_UpdateVpcLink_601557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_601569.validator(path, query, header, formData, body)
  let scheme = call_601569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601569.url(scheme.get, call_601569.host, call_601569.base,
                         call_601569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601569, url, valid)

proc call*(call_601570: Call_UpdateVpcLink_601557; body: JsonNode; vpclinkId: string): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   body: JObject (required)
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_601571 = newJObject()
  var body_601572 = newJObject()
  if body != nil:
    body_601572 = body
  add(path_601571, "vpclink_id", newJString(vpclinkId))
  result = call_601570.call(path_601571, nil, nil, nil, body_601572)

var updateVpcLink* = Call_UpdateVpcLink_601557(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_601558,
    base: "/", url: url_UpdateVpcLink_601559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_601543 = ref object of OpenApiRestCall_599352
proc url_DeleteVpcLink_601545(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVpcLink_601544(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601546 = path.getOrDefault("vpclink_id")
  valid_601546 = validateParameter(valid_601546, JString, required = true,
                                 default = nil)
  if valid_601546 != nil:
    section.add "vpclink_id", valid_601546
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
  var valid_601547 = header.getOrDefault("X-Amz-Date")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Date", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Security-Token")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Security-Token", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Content-Sha256", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Algorithm")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Algorithm", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Signature")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Signature", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-SignedHeaders", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Credential")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Credential", valid_601553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601554: Call_DeleteVpcLink_601543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_601554.validator(path, query, header, formData, body)
  let scheme = call_601554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601554.url(scheme.get, call_601554.host, call_601554.base,
                         call_601554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601554, url, valid)

proc call*(call_601555: Call_DeleteVpcLink_601543; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_601556 = newJObject()
  add(path_601556, "vpclink_id", newJString(vpclinkId))
  result = call_601555.call(path_601556, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_601543(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_601544,
    base: "/", url: url_DeleteVpcLink_601545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_601573 = ref object of OpenApiRestCall_599352
proc url_FlushStageAuthorizersCache_601575(protocol: Scheme; host: string;
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

proc validate_FlushStageAuthorizersCache_601574(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stage_name: JString (required)
  ##             : The name of the stage to flush.
  ##   restapi_id: JString (required)
  ##             : The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `stage_name` field"
  var valid_601576 = path.getOrDefault("stage_name")
  valid_601576 = validateParameter(valid_601576, JString, required = true,
                                 default = nil)
  if valid_601576 != nil:
    section.add "stage_name", valid_601576
  var valid_601577 = path.getOrDefault("restapi_id")
  valid_601577 = validateParameter(valid_601577, JString, required = true,
                                 default = nil)
  if valid_601577 != nil:
    section.add "restapi_id", valid_601577
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
  var valid_601578 = header.getOrDefault("X-Amz-Date")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Date", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Security-Token")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Security-Token", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Content-Sha256", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Algorithm")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Algorithm", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Signature")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Signature", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-SignedHeaders", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Credential")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Credential", valid_601584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601585: Call_FlushStageAuthorizersCache_601573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_601585.validator(path, query, header, formData, body)
  let scheme = call_601585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601585.url(scheme.get, call_601585.host, call_601585.base,
                         call_601585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601585, url, valid)

proc call*(call_601586: Call_FlushStageAuthorizersCache_601573; stageName: string;
          restapiId: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  var path_601587 = newJObject()
  add(path_601587, "stage_name", newJString(stageName))
  add(path_601587, "restapi_id", newJString(restapiId))
  result = call_601586.call(path_601587, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_601573(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_601574, base: "/",
    url: url_FlushStageAuthorizersCache_601575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_601588 = ref object of OpenApiRestCall_599352
proc url_FlushStageCache_601590(protocol: Scheme; host: string; base: string;
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

proc validate_FlushStageCache_601589(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Flushes a stage's cache.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stage_name: JString (required)
  ##             : [Required] The name of the stage to flush its cache.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `stage_name` field"
  var valid_601591 = path.getOrDefault("stage_name")
  valid_601591 = validateParameter(valid_601591, JString, required = true,
                                 default = nil)
  if valid_601591 != nil:
    section.add "stage_name", valid_601591
  var valid_601592 = path.getOrDefault("restapi_id")
  valid_601592 = validateParameter(valid_601592, JString, required = true,
                                 default = nil)
  if valid_601592 != nil:
    section.add "restapi_id", valid_601592
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
  var valid_601593 = header.getOrDefault("X-Amz-Date")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Date", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Security-Token")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Security-Token", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Content-Sha256", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Algorithm")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Algorithm", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Signature")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Signature", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-SignedHeaders", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Credential")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Credential", valid_601599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601600: Call_FlushStageCache_601588; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_601600.validator(path, query, header, formData, body)
  let scheme = call_601600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601600.url(scheme.get, call_601600.host, call_601600.base,
                         call_601600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601600, url, valid)

proc call*(call_601601: Call_FlushStageCache_601588; stageName: string;
          restapiId: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601602 = newJObject()
  add(path_601602, "stage_name", newJString(stageName))
  add(path_601602, "restapi_id", newJString(restapiId))
  result = call_601601.call(path_601602, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_601588(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_601589, base: "/", url: url_FlushStageCache_601590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_601618 = ref object of OpenApiRestCall_599352
proc url_GenerateClientCertificate_601620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateClientCertificate_601619(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601621 = header.getOrDefault("X-Amz-Date")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Date", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Security-Token")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Security-Token", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Content-Sha256", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Algorithm")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Algorithm", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Signature")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Signature", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-SignedHeaders", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Credential")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Credential", valid_601627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601629: Call_GenerateClientCertificate_601618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_601629.validator(path, query, header, formData, body)
  let scheme = call_601629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601629.url(scheme.get, call_601629.host, call_601629.base,
                         call_601629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601629, url, valid)

proc call*(call_601630: Call_GenerateClientCertificate_601618; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_601631 = newJObject()
  if body != nil:
    body_601631 = body
  result = call_601630.call(nil, nil, nil, nil, body_601631)

var generateClientCertificate* = Call_GenerateClientCertificate_601618(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_601619, base: "/",
    url: url_GenerateClientCertificate_601620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_601603 = ref object of OpenApiRestCall_599352
proc url_GetClientCertificates_601605(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClientCertificates_601604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601606 = query.getOrDefault("position")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "position", valid_601606
  var valid_601607 = query.getOrDefault("limit")
  valid_601607 = validateParameter(valid_601607, JInt, required = false, default = nil)
  if valid_601607 != nil:
    section.add "limit", valid_601607
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
  var valid_601608 = header.getOrDefault("X-Amz-Date")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Date", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Security-Token")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Security-Token", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Content-Sha256", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Algorithm")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Algorithm", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Signature")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Signature", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-SignedHeaders", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Credential")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Credential", valid_601614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601615: Call_GetClientCertificates_601603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_601615.validator(path, query, header, formData, body)
  let scheme = call_601615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601615.url(scheme.get, call_601615.host, call_601615.base,
                         call_601615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601615, url, valid)

proc call*(call_601616: Call_GetClientCertificates_601603; position: string = "";
          limit: int = 0): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_601617 = newJObject()
  add(query_601617, "position", newJString(position))
  add(query_601617, "limit", newJInt(limit))
  result = call_601616.call(nil, query_601617, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_601603(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_601604, base: "/",
    url: url_GetClientCertificates_601605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_601632 = ref object of OpenApiRestCall_599352
proc url_GetAccount_601634(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccount_601633(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601635 = header.getOrDefault("X-Amz-Date")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Date", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Security-Token")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Security-Token", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Content-Sha256", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Algorithm")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Algorithm", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Signature")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Signature", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-SignedHeaders", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Credential")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Credential", valid_601641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601642: Call_GetAccount_601632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_601642.validator(path, query, header, formData, body)
  let scheme = call_601642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601642.url(scheme.get, call_601642.host, call_601642.base,
                         call_601642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601642, url, valid)

proc call*(call_601643: Call_GetAccount_601632): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_601643.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_601632(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_601633,
                                      base: "/", url: url_GetAccount_601634,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_601644 = ref object of OpenApiRestCall_599352
proc url_UpdateAccount_601646(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAccount_601645(path: JsonNode; query: JsonNode; header: JsonNode;
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

proc call*(call_601655: Call_UpdateAccount_601644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_601655.validator(path, query, header, formData, body)
  let scheme = call_601655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601655.url(scheme.get, call_601655.host, call_601655.base,
                         call_601655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601655, url, valid)

proc call*(call_601656: Call_UpdateAccount_601644; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_601657 = newJObject()
  if body != nil:
    body_601657 = body
  result = call_601656.call(nil, nil, nil, nil, body_601657)

var updateAccount* = Call_UpdateAccount_601644(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_601645, base: "/", url: url_UpdateAccount_601646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_601658 = ref object of OpenApiRestCall_599352
proc url_GetExport_601660(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetExport_601659(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   export_type: JString (required)
  ##              : [Required] The type of export. Acceptable values are 'oas30' for OpenAPI 3.0.x and 'swagger' for Swagger/OpenAPI 2.0.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> that will be exported.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `export_type` field"
  var valid_601661 = path.getOrDefault("export_type")
  valid_601661 = validateParameter(valid_601661, JString, required = true,
                                 default = nil)
  if valid_601661 != nil:
    section.add "export_type", valid_601661
  var valid_601662 = path.getOrDefault("stage_name")
  valid_601662 = validateParameter(valid_601662, JString, required = true,
                                 default = nil)
  if valid_601662 != nil:
    section.add "stage_name", valid_601662
  var valid_601663 = path.getOrDefault("restapi_id")
  valid_601663 = validateParameter(valid_601663, JString, required = true,
                                 default = nil)
  if valid_601663 != nil:
    section.add "restapi_id", valid_601663
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_601664 = query.getOrDefault("parameters.0.value")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "parameters.0.value", valid_601664
  var valid_601665 = query.getOrDefault("parameters.2.value")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "parameters.2.value", valid_601665
  var valid_601666 = query.getOrDefault("parameters.1.key")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "parameters.1.key", valid_601666
  var valid_601667 = query.getOrDefault("parameters.0.key")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "parameters.0.key", valid_601667
  var valid_601668 = query.getOrDefault("parameters.2.key")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "parameters.2.key", valid_601668
  var valid_601669 = query.getOrDefault("parameters.1.value")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "parameters.1.value", valid_601669
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   Accept: JString
  ##         : The content-type of the export, for example <code>application/json</code>. Currently <code>application/json</code> and <code>application/yaml</code> are supported for <code>exportType</code> of<code>oas30</code> and <code>swagger</code>. This should be specified in the <code>Accept</code> header for direct API requests.
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601670 = header.getOrDefault("X-Amz-Date")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Date", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Security-Token")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Security-Token", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Content-Sha256", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Algorithm")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Algorithm", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-Signature")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Signature", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-SignedHeaders", valid_601675
  var valid_601676 = header.getOrDefault("Accept")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "Accept", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Credential")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Credential", valid_601677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601678: Call_GetExport_601658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_601678.validator(path, query, header, formData, body)
  let scheme = call_601678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601678.url(scheme.get, call_601678.host, call_601678.base,
                         call_601678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601678, url, valid)

proc call*(call_601679: Call_GetExport_601658; exportType: string; stageName: string;
          restapiId: string; parameters0Value: string = "";
          parameters2Value: string = ""; parameters1Key: string = "";
          parameters0Key: string = ""; parameters2Key: string = "";
          parameters1Value: string = ""): Recallable =
  ## getExport
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ##   parameters0Value: string
  ##   parameters2Value: string
  ##   parameters1Key: string
  ##   parameters0Key: string
  ##   exportType: string (required)
  ##             : [Required] The type of export. Acceptable values are 'oas30' for OpenAPI 3.0.x and 'swagger' for Swagger/OpenAPI 2.0.
  ##   parameters2Key: string
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> that will be exported.
  ##   parameters1Value: string
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601680 = newJObject()
  var query_601681 = newJObject()
  add(query_601681, "parameters.0.value", newJString(parameters0Value))
  add(query_601681, "parameters.2.value", newJString(parameters2Value))
  add(query_601681, "parameters.1.key", newJString(parameters1Key))
  add(query_601681, "parameters.0.key", newJString(parameters0Key))
  add(path_601680, "export_type", newJString(exportType))
  add(query_601681, "parameters.2.key", newJString(parameters2Key))
  add(path_601680, "stage_name", newJString(stageName))
  add(query_601681, "parameters.1.value", newJString(parameters1Value))
  add(path_601680, "restapi_id", newJString(restapiId))
  result = call_601679.call(path_601680, query_601681, nil, nil, nil)

var getExport* = Call_GetExport_601658(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_601659,
                                    base: "/", url: url_GetExport_601660,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_601682 = ref object of OpenApiRestCall_599352
proc url_GetGatewayResponses_601684(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponses_601683(path: JsonNode; query: JsonNode;
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
  var valid_601685 = path.getOrDefault("restapi_id")
  valid_601685 = validateParameter(valid_601685, JString, required = true,
                                 default = nil)
  if valid_601685 != nil:
    section.add "restapi_id", valid_601685
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  section = newJObject()
  var valid_601686 = query.getOrDefault("position")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "position", valid_601686
  var valid_601687 = query.getOrDefault("limit")
  valid_601687 = validateParameter(valid_601687, JInt, required = false, default = nil)
  if valid_601687 != nil:
    section.add "limit", valid_601687
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
  var valid_601688 = header.getOrDefault("X-Amz-Date")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Date", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Security-Token")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Security-Token", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Content-Sha256", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Algorithm")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Algorithm", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Signature")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Signature", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-SignedHeaders", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Credential")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Credential", valid_601694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601695: Call_GetGatewayResponses_601682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_601695.validator(path, query, header, formData, body)
  let scheme = call_601695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601695.url(scheme.get, call_601695.host, call_601695.base,
                         call_601695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601695, url, valid)

proc call*(call_601696: Call_GetGatewayResponses_601682; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601697 = newJObject()
  var query_601698 = newJObject()
  add(query_601698, "position", newJString(position))
  add(query_601698, "limit", newJInt(limit))
  add(path_601697, "restapi_id", newJString(restapiId))
  result = call_601696.call(path_601697, query_601698, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_601682(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_601683, base: "/",
    url: url_GetGatewayResponses_601684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_601699 = ref object of OpenApiRestCall_599352
proc url_GetModelTemplate_601701(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_601700(path: JsonNode; query: JsonNode;
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
  var valid_601702 = path.getOrDefault("model_name")
  valid_601702 = validateParameter(valid_601702, JString, required = true,
                                 default = nil)
  if valid_601702 != nil:
    section.add "model_name", valid_601702
  var valid_601703 = path.getOrDefault("restapi_id")
  valid_601703 = validateParameter(valid_601703, JString, required = true,
                                 default = nil)
  if valid_601703 != nil:
    section.add "restapi_id", valid_601703
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
  var valid_601704 = header.getOrDefault("X-Amz-Date")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Date", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Security-Token")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Security-Token", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Content-Sha256", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Algorithm")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Algorithm", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Signature")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Signature", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-SignedHeaders", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Credential")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Credential", valid_601710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601711: Call_GetModelTemplate_601699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_601711.validator(path, query, header, formData, body)
  let scheme = call_601711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601711.url(scheme.get, call_601711.host, call_601711.base,
                         call_601711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601711, url, valid)

proc call*(call_601712: Call_GetModelTemplate_601699; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601713 = newJObject()
  add(path_601713, "model_name", newJString(modelName))
  add(path_601713, "restapi_id", newJString(restapiId))
  result = call_601712.call(path_601713, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_601699(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_601700, base: "/",
    url: url_GetModelTemplate_601701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_601714 = ref object of OpenApiRestCall_599352
proc url_GetResources_601716(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_601715(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601717 = path.getOrDefault("restapi_id")
  valid_601717 = validateParameter(valid_601717, JString, required = true,
                                 default = nil)
  if valid_601717 != nil:
    section.add "restapi_id", valid_601717
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601718 = query.getOrDefault("embed")
  valid_601718 = validateParameter(valid_601718, JArray, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "embed", valid_601718
  var valid_601719 = query.getOrDefault("position")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "position", valid_601719
  var valid_601720 = query.getOrDefault("limit")
  valid_601720 = validateParameter(valid_601720, JInt, required = false, default = nil)
  if valid_601720 != nil:
    section.add "limit", valid_601720
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
  var valid_601721 = header.getOrDefault("X-Amz-Date")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Date", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Security-Token")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Security-Token", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Content-Sha256", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Algorithm")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Algorithm", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Signature")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Signature", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-SignedHeaders", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Credential")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Credential", valid_601727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601728: Call_GetResources_601714; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_601728.validator(path, query, header, formData, body)
  let scheme = call_601728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601728.url(scheme.get, call_601728.host, call_601728.base,
                         call_601728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601728, url, valid)

proc call*(call_601729: Call_GetResources_601714; restapiId: string;
          embed: JsonNode = nil; position: string = ""; limit: int = 0): Recallable =
  ## getResources
  ## Lists information about a collection of <a>Resource</a> resources.
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601730 = newJObject()
  var query_601731 = newJObject()
  if embed != nil:
    query_601731.add "embed", embed
  add(query_601731, "position", newJString(position))
  add(query_601731, "limit", newJInt(limit))
  add(path_601730, "restapi_id", newJString(restapiId))
  result = call_601729.call(path_601730, query_601731, nil, nil, nil)

var getResources* = Call_GetResources_601714(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_601715,
    base: "/", url: url_GetResources_601716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_601732 = ref object of OpenApiRestCall_599352
proc url_GetSdk_601734(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdk_601733(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdk_type: JString (required)
  ##           : [Required] The language for the generated SDK. Currently <code>java</code>, <code>javascript</code>, <code>android</code>, <code>objectivec</code> (for iOS), <code>swift</code> (for iOS), and <code>ruby</code> are supported.
  ##   stage_name: JString (required)
  ##             : [Required] The name of the <a>Stage</a> that the SDK will use.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `sdk_type` field"
  var valid_601735 = path.getOrDefault("sdk_type")
  valid_601735 = validateParameter(valid_601735, JString, required = true,
                                 default = nil)
  if valid_601735 != nil:
    section.add "sdk_type", valid_601735
  var valid_601736 = path.getOrDefault("stage_name")
  valid_601736 = validateParameter(valid_601736, JString, required = true,
                                 default = nil)
  if valid_601736 != nil:
    section.add "stage_name", valid_601736
  var valid_601737 = path.getOrDefault("restapi_id")
  valid_601737 = validateParameter(valid_601737, JString, required = true,
                                 default = nil)
  if valid_601737 != nil:
    section.add "restapi_id", valid_601737
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_601738 = query.getOrDefault("parameters.0.value")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "parameters.0.value", valid_601738
  var valid_601739 = query.getOrDefault("parameters.2.value")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "parameters.2.value", valid_601739
  var valid_601740 = query.getOrDefault("parameters.1.key")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "parameters.1.key", valid_601740
  var valid_601741 = query.getOrDefault("parameters.0.key")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "parameters.0.key", valid_601741
  var valid_601742 = query.getOrDefault("parameters.2.key")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "parameters.2.key", valid_601742
  var valid_601743 = query.getOrDefault("parameters.1.value")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "parameters.1.value", valid_601743
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
  if body != nil:
    result.add "body", body

proc call*(call_601751: Call_GetSdk_601732; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_601751.validator(path, query, header, formData, body)
  let scheme = call_601751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601751.url(scheme.get, call_601751.host, call_601751.base,
                         call_601751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601751, url, valid)

proc call*(call_601752: Call_GetSdk_601732; sdkType: string; stageName: string;
          restapiId: string; parameters0Value: string = "";
          parameters2Value: string = ""; parameters1Key: string = "";
          parameters0Key: string = ""; parameters2Key: string = "";
          parameters1Value: string = ""): Recallable =
  ## getSdk
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ##   sdkType: string (required)
  ##          : [Required] The language for the generated SDK. Currently <code>java</code>, <code>javascript</code>, <code>android</code>, <code>objectivec</code> (for iOS), <code>swift</code> (for iOS), and <code>ruby</code> are supported.
  ##   parameters0Value: string
  ##   parameters2Value: string
  ##   parameters1Key: string
  ##   parameters0Key: string
  ##   parameters2Key: string
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> that the SDK will use.
  ##   parameters1Value: string
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601753 = newJObject()
  var query_601754 = newJObject()
  add(path_601753, "sdk_type", newJString(sdkType))
  add(query_601754, "parameters.0.value", newJString(parameters0Value))
  add(query_601754, "parameters.2.value", newJString(parameters2Value))
  add(query_601754, "parameters.1.key", newJString(parameters1Key))
  add(query_601754, "parameters.0.key", newJString(parameters0Key))
  add(query_601754, "parameters.2.key", newJString(parameters2Key))
  add(path_601753, "stage_name", newJString(stageName))
  add(query_601754, "parameters.1.value", newJString(parameters1Value))
  add(path_601753, "restapi_id", newJString(restapiId))
  result = call_601752.call(path_601753, query_601754, nil, nil, nil)

var getSdk* = Call_GetSdk_601732(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_601733, base: "/",
                              url: url_GetSdk_601734,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_601755 = ref object of OpenApiRestCall_599352
proc url_GetSdkType_601757(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdkType_601756(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_601758 = path.getOrDefault("sdktype_id")
  valid_601758 = validateParameter(valid_601758, JString, required = true,
                                 default = nil)
  if valid_601758 != nil:
    section.add "sdktype_id", valid_601758
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
  var valid_601759 = header.getOrDefault("X-Amz-Date")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Date", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Security-Token")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Security-Token", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Content-Sha256", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Algorithm")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Algorithm", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Signature")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Signature", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-SignedHeaders", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Credential")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Credential", valid_601765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601766: Call_GetSdkType_601755; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601766.validator(path, query, header, formData, body)
  let scheme = call_601766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601766.url(scheme.get, call_601766.host, call_601766.base,
                         call_601766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601766, url, valid)

proc call*(call_601767: Call_GetSdkType_601755; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_601768 = newJObject()
  add(path_601768, "sdktype_id", newJString(sdktypeId))
  result = call_601767.call(path_601768, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_601755(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_601756,
                                      base: "/", url: url_GetSdkType_601757,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_601769 = ref object of OpenApiRestCall_599352
proc url_GetSdkTypes_601771(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSdkTypes_601770(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601772 = query.getOrDefault("position")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "position", valid_601772
  var valid_601773 = query.getOrDefault("limit")
  valid_601773 = validateParameter(valid_601773, JInt, required = false, default = nil)
  if valid_601773 != nil:
    section.add "limit", valid_601773
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
  var valid_601774 = header.getOrDefault("X-Amz-Date")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Date", valid_601774
  var valid_601775 = header.getOrDefault("X-Amz-Security-Token")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Security-Token", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Content-Sha256", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Algorithm")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Algorithm", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Signature")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Signature", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-SignedHeaders", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Credential")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Credential", valid_601780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601781: Call_GetSdkTypes_601769; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601781.validator(path, query, header, formData, body)
  let scheme = call_601781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601781.url(scheme.get, call_601781.host, call_601781.base,
                         call_601781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601781, url, valid)

proc call*(call_601782: Call_GetSdkTypes_601769; position: string = ""; limit: int = 0): Recallable =
  ## getSdkTypes
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_601783 = newJObject()
  add(query_601783, "position", newJString(position))
  add(query_601783, "limit", newJInt(limit))
  result = call_601782.call(nil, query_601783, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_601769(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_601770,
                                        base: "/", url: url_GetSdkTypes_601771,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601801 = ref object of OpenApiRestCall_599352
proc url_TagResource_601803(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_601802(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601804 = path.getOrDefault("resource_arn")
  valid_601804 = validateParameter(valid_601804, JString, required = true,
                                 default = nil)
  if valid_601804 != nil:
    section.add "resource_arn", valid_601804
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
  var valid_601805 = header.getOrDefault("X-Amz-Date")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-Date", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-Security-Token")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Security-Token", valid_601806
  var valid_601807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "X-Amz-Content-Sha256", valid_601807
  var valid_601808 = header.getOrDefault("X-Amz-Algorithm")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "X-Amz-Algorithm", valid_601808
  var valid_601809 = header.getOrDefault("X-Amz-Signature")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Signature", valid_601809
  var valid_601810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-SignedHeaders", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Credential")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Credential", valid_601811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601813: Call_TagResource_601801; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_601813.validator(path, query, header, formData, body)
  let scheme = call_601813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601813.url(scheme.get, call_601813.host, call_601813.base,
                         call_601813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601813, url, valid)

proc call*(call_601814: Call_TagResource_601801; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_601815 = newJObject()
  var body_601816 = newJObject()
  add(path_601815, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_601816 = body
  result = call_601814.call(path_601815, nil, nil, nil, body_601816)

var tagResource* = Call_TagResource_601801(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_601802,
                                        base: "/", url: url_TagResource_601803,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_601784 = ref object of OpenApiRestCall_599352
proc url_GetTags_601786(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_601785(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601787 = path.getOrDefault("resource_arn")
  valid_601787 = validateParameter(valid_601787, JString, required = true,
                                 default = nil)
  if valid_601787 != nil:
    section.add "resource_arn", valid_601787
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601788 = query.getOrDefault("position")
  valid_601788 = validateParameter(valid_601788, JString, required = false,
                                 default = nil)
  if valid_601788 != nil:
    section.add "position", valid_601788
  var valid_601789 = query.getOrDefault("limit")
  valid_601789 = validateParameter(valid_601789, JInt, required = false, default = nil)
  if valid_601789 != nil:
    section.add "limit", valid_601789
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
  var valid_601790 = header.getOrDefault("X-Amz-Date")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-Date", valid_601790
  var valid_601791 = header.getOrDefault("X-Amz-Security-Token")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Security-Token", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Content-Sha256", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Algorithm")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Algorithm", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Signature")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Signature", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-SignedHeaders", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Credential")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Credential", valid_601796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601797: Call_GetTags_601784; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_601797.validator(path, query, header, formData, body)
  let scheme = call_601797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601797.url(scheme.get, call_601797.host, call_601797.base,
                         call_601797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601797, url, valid)

proc call*(call_601798: Call_GetTags_601784; resourceArn: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_601799 = newJObject()
  var query_601800 = newJObject()
  add(path_601799, "resource_arn", newJString(resourceArn))
  add(query_601800, "position", newJString(position))
  add(query_601800, "limit", newJInt(limit))
  result = call_601798.call(path_601799, query_601800, nil, nil, nil)

var getTags* = Call_GetTags_601784(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_601785, base: "/",
                                url: url_GetTags_601786,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_601817 = ref object of OpenApiRestCall_599352
proc url_GetUsage_601819(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUsage_601818(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601820 = path.getOrDefault("usageplanId")
  valid_601820 = validateParameter(valid_601820, JString, required = true,
                                 default = nil)
  if valid_601820 != nil:
    section.add "usageplanId", valid_601820
  result.add "path", section
  ## parameters in `query` object:
  ##   endDate: JString (required)
  ##          : [Required] The ending date (e.g., 2016-12-31) of the usage data.
  ##   startDate: JString (required)
  ##            : [Required] The starting date (e.g., 2016-01-01) of the usage data.
  ##   keyId: JString
  ##        : The Id of the API key associated with the resultant usage data.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `endDate` field"
  var valid_601821 = query.getOrDefault("endDate")
  valid_601821 = validateParameter(valid_601821, JString, required = true,
                                 default = nil)
  if valid_601821 != nil:
    section.add "endDate", valid_601821
  var valid_601822 = query.getOrDefault("startDate")
  valid_601822 = validateParameter(valid_601822, JString, required = true,
                                 default = nil)
  if valid_601822 != nil:
    section.add "startDate", valid_601822
  var valid_601823 = query.getOrDefault("keyId")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "keyId", valid_601823
  var valid_601824 = query.getOrDefault("position")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "position", valid_601824
  var valid_601825 = query.getOrDefault("limit")
  valid_601825 = validateParameter(valid_601825, JInt, required = false, default = nil)
  if valid_601825 != nil:
    section.add "limit", valid_601825
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
  var valid_601826 = header.getOrDefault("X-Amz-Date")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Date", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Security-Token")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Security-Token", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Content-Sha256", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Algorithm")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Algorithm", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Signature")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Signature", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-SignedHeaders", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-Credential")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Credential", valid_601832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601833: Call_GetUsage_601817; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_601833.validator(path, query, header, formData, body)
  let scheme = call_601833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601833.url(scheme.get, call_601833.host, call_601833.base,
                         call_601833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601833, url, valid)

proc call*(call_601834: Call_GetUsage_601817; endDate: string; startDate: string;
          usageplanId: string; keyId: string = ""; position: string = ""; limit: int = 0): Recallable =
  ## getUsage
  ## Gets the usage data of a usage plan in a specified time interval.
  ##   endDate: string (required)
  ##          : [Required] The ending date (e.g., 2016-12-31) of the usage data.
  ##   startDate: string (required)
  ##            : [Required] The starting date (e.g., 2016-01-01) of the usage data.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   keyId: string
  ##        : The Id of the API key associated with the resultant usage data.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_601835 = newJObject()
  var query_601836 = newJObject()
  add(query_601836, "endDate", newJString(endDate))
  add(query_601836, "startDate", newJString(startDate))
  add(path_601835, "usageplanId", newJString(usageplanId))
  add(query_601836, "keyId", newJString(keyId))
  add(query_601836, "position", newJString(position))
  add(query_601836, "limit", newJInt(limit))
  result = call_601834.call(path_601835, query_601836, nil, nil, nil)

var getUsage* = Call_GetUsage_601817(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_601818, base: "/",
                                  url: url_GetUsage_601819,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_601837 = ref object of OpenApiRestCall_599352
proc url_ImportApiKeys_601839(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApiKeys_601838(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString (required)
  ##   failonwarnings: JBool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   format: JString (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_601840 = query.getOrDefault("mode")
  valid_601840 = validateParameter(valid_601840, JString, required = true,
                                 default = newJString("import"))
  if valid_601840 != nil:
    section.add "mode", valid_601840
  var valid_601841 = query.getOrDefault("failonwarnings")
  valid_601841 = validateParameter(valid_601841, JBool, required = false, default = nil)
  if valid_601841 != nil:
    section.add "failonwarnings", valid_601841
  var valid_601842 = query.getOrDefault("format")
  valid_601842 = validateParameter(valid_601842, JString, required = true,
                                 default = newJString("csv"))
  if valid_601842 != nil:
    section.add "format", valid_601842
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
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Security-Token")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Security-Token", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Content-Sha256", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Algorithm")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Algorithm", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Signature")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Signature", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-SignedHeaders", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Credential")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Credential", valid_601849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601851: Call_ImportApiKeys_601837; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_601851.validator(path, query, header, formData, body)
  let scheme = call_601851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601851.url(scheme.get, call_601851.host, call_601851.base,
                         call_601851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601851, url, valid)

proc call*(call_601852: Call_ImportApiKeys_601837; body: JsonNode;
          mode: string = "import"; failonwarnings: bool = false; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   mode: string (required)
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_601853 = newJObject()
  var body_601854 = newJObject()
  add(query_601853, "mode", newJString(mode))
  add(query_601853, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_601854 = body
  add(query_601853, "format", newJString(format))
  result = call_601852.call(nil, query_601853, nil, nil, body_601854)

var importApiKeys* = Call_ImportApiKeys_601837(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_601838,
    base: "/", url: url_ImportApiKeys_601839, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_601855 = ref object of OpenApiRestCall_599352
proc url_ImportRestApi_601857(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportRestApi_601856(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   mode: JString (required)
  ##   parameters.2.key: JString
  ##   failonwarnings: JBool
  ##                 : A query parameter to indicate whether to rollback the API creation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_601858 = query.getOrDefault("parameters.0.value")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "parameters.0.value", valid_601858
  var valid_601859 = query.getOrDefault("parameters.2.value")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "parameters.2.value", valid_601859
  var valid_601860 = query.getOrDefault("parameters.1.key")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "parameters.1.key", valid_601860
  var valid_601861 = query.getOrDefault("parameters.0.key")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "parameters.0.key", valid_601861
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_601862 = query.getOrDefault("mode")
  valid_601862 = validateParameter(valid_601862, JString, required = true,
                                 default = newJString("import"))
  if valid_601862 != nil:
    section.add "mode", valid_601862
  var valid_601863 = query.getOrDefault("parameters.2.key")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "parameters.2.key", valid_601863
  var valid_601864 = query.getOrDefault("failonwarnings")
  valid_601864 = validateParameter(valid_601864, JBool, required = false, default = nil)
  if valid_601864 != nil:
    section.add "failonwarnings", valid_601864
  var valid_601865 = query.getOrDefault("parameters.1.value")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "parameters.1.value", valid_601865
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
  var valid_601866 = header.getOrDefault("X-Amz-Date")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Date", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-Security-Token")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Security-Token", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Content-Sha256", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Algorithm")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Algorithm", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Signature")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Signature", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-SignedHeaders", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Credential")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Credential", valid_601872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601874: Call_ImportRestApi_601855; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_601874.validator(path, query, header, formData, body)
  let scheme = call_601874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601874.url(scheme.get, call_601874.host, call_601874.base,
                         call_601874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601874, url, valid)

proc call*(call_601875: Call_ImportRestApi_601855; body: JsonNode;
          parameters0Value: string = ""; parameters2Value: string = "";
          parameters1Key: string = ""; parameters0Key: string = "";
          mode: string = "import"; parameters2Key: string = "";
          failonwarnings: bool = false; parameters1Value: string = ""): Recallable =
  ## importRestApi
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ##   parameters0Value: string
  ##   parameters2Value: string
  ##   parameters1Key: string
  ##   parameters0Key: string
  ##   mode: string (required)
  ##   parameters2Key: string
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback the API creation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   parameters1Value: string
  var query_601876 = newJObject()
  var body_601877 = newJObject()
  add(query_601876, "parameters.0.value", newJString(parameters0Value))
  add(query_601876, "parameters.2.value", newJString(parameters2Value))
  add(query_601876, "parameters.1.key", newJString(parameters1Key))
  add(query_601876, "parameters.0.key", newJString(parameters0Key))
  add(query_601876, "mode", newJString(mode))
  add(query_601876, "parameters.2.key", newJString(parameters2Key))
  add(query_601876, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_601877 = body
  add(query_601876, "parameters.1.value", newJString(parameters1Value))
  result = call_601875.call(nil, query_601876, nil, nil, body_601877)

var importRestApi* = Call_ImportRestApi_601855(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_601856,
    base: "/", url: url_ImportRestApi_601857, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601878 = ref object of OpenApiRestCall_599352
proc url_UntagResource_601880(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_601879(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601881 = path.getOrDefault("resource_arn")
  valid_601881 = validateParameter(valid_601881, JString, required = true,
                                 default = nil)
  if valid_601881 != nil:
    section.add "resource_arn", valid_601881
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601882 = query.getOrDefault("tagKeys")
  valid_601882 = validateParameter(valid_601882, JArray, required = true, default = nil)
  if valid_601882 != nil:
    section.add "tagKeys", valid_601882
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
  var valid_601883 = header.getOrDefault("X-Amz-Date")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Date", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Security-Token")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Security-Token", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Content-Sha256", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Algorithm")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Algorithm", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Signature")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Signature", valid_601887
  var valid_601888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-SignedHeaders", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-Credential")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-Credential", valid_601889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601890: Call_UntagResource_601878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_601890.validator(path, query, header, formData, body)
  let scheme = call_601890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601890.url(scheme.get, call_601890.host, call_601890.base,
                         call_601890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601890, url, valid)

proc call*(call_601891: Call_UntagResource_601878; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_601892 = newJObject()
  var query_601893 = newJObject()
  add(path_601892, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_601893.add "tagKeys", tagKeys
  result = call_601891.call(path_601892, query_601893, nil, nil, nil)

var untagResource* = Call_UntagResource_601878(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_601879,
    base: "/", url: url_UntagResource_601880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_601894 = ref object of OpenApiRestCall_599352
proc url_UpdateUsage_601896(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsage_601895(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   keyId: JString (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: JString (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `keyId` field"
  var valid_601897 = path.getOrDefault("keyId")
  valid_601897 = validateParameter(valid_601897, JString, required = true,
                                 default = nil)
  if valid_601897 != nil:
    section.add "keyId", valid_601897
  var valid_601898 = path.getOrDefault("usageplanId")
  valid_601898 = validateParameter(valid_601898, JString, required = true,
                                 default = nil)
  if valid_601898 != nil:
    section.add "usageplanId", valid_601898
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
  var valid_601899 = header.getOrDefault("X-Amz-Date")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Date", valid_601899
  var valid_601900 = header.getOrDefault("X-Amz-Security-Token")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Security-Token", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Content-Sha256", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Algorithm")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Algorithm", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-Signature")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-Signature", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-SignedHeaders", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Credential")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Credential", valid_601905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601907: Call_UpdateUsage_601894; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_601907.validator(path, query, header, formData, body)
  let scheme = call_601907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601907.url(scheme.get, call_601907.host, call_601907.base,
                         call_601907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601907, url, valid)

proc call*(call_601908: Call_UpdateUsage_601894; keyId: string; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   body: JObject (required)
  var path_601909 = newJObject()
  var body_601910 = newJObject()
  add(path_601909, "keyId", newJString(keyId))
  add(path_601909, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_601910 = body
  result = call_601908.call(path_601909, nil, nil, nil, body_601910)

var updateUsage* = Call_UpdateUsage_601894(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_601895,
                                        base: "/", url: url_UpdateUsage_601896,
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
