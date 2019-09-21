
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602417 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602417](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602417): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_603014 = ref object of OpenApiRestCall_602417
proc url_CreateApiKey_603016(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApiKey_603015(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603017 = header.getOrDefault("X-Amz-Date")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Date", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-Security-Token")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Security-Token", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Content-Sha256", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-Algorithm")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Algorithm", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Signature")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Signature", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-SignedHeaders", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-Credential")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Credential", valid_603023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603025: Call_CreateApiKey_603014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_603025.validator(path, query, header, formData, body)
  let scheme = call_603025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603025.url(scheme.get, call_603025.host, call_603025.base,
                         call_603025.route, valid.getOrDefault("path"))
  result = hook(call_603025, url, valid)

proc call*(call_603026: Call_CreateApiKey_603014; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_603027 = newJObject()
  if body != nil:
    body_603027 = body
  result = call_603026.call(nil, nil, nil, nil, body_603027)

var createApiKey* = Call_CreateApiKey_603014(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_603015, base: "/", url: url_CreateApiKey_603016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_602754 = ref object of OpenApiRestCall_602417
proc url_GetApiKeys_602756(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApiKeys_602755(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602868 = query.getOrDefault("customerId")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "customerId", valid_602868
  var valid_602869 = query.getOrDefault("includeValues")
  valid_602869 = validateParameter(valid_602869, JBool, required = false, default = nil)
  if valid_602869 != nil:
    section.add "includeValues", valid_602869
  var valid_602870 = query.getOrDefault("name")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "name", valid_602870
  var valid_602871 = query.getOrDefault("position")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "position", valid_602871
  var valid_602872 = query.getOrDefault("limit")
  valid_602872 = validateParameter(valid_602872, JInt, required = false, default = nil)
  if valid_602872 != nil:
    section.add "limit", valid_602872
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
  var valid_602873 = header.getOrDefault("X-Amz-Date")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Date", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Security-Token")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Security-Token", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Content-Sha256", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Algorithm")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Algorithm", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Signature")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Signature", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-SignedHeaders", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Credential")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Credential", valid_602879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602902: Call_GetApiKeys_602754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_602902.validator(path, query, header, formData, body)
  let scheme = call_602902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602902.url(scheme.get, call_602902.host, call_602902.base,
                         call_602902.route, valid.getOrDefault("path"))
  result = hook(call_602902, url, valid)

proc call*(call_602973: Call_GetApiKeys_602754; customerId: string = "";
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
  var query_602974 = newJObject()
  add(query_602974, "customerId", newJString(customerId))
  add(query_602974, "includeValues", newJBool(includeValues))
  add(query_602974, "name", newJString(name))
  add(query_602974, "position", newJString(position))
  add(query_602974, "limit", newJInt(limit))
  result = call_602973.call(nil, query_602974, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_602754(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_602755,
                                      base: "/", url: url_GetApiKeys_602756,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_603059 = ref object of OpenApiRestCall_602417
proc url_CreateAuthorizer_603061(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateAuthorizer_603060(path: JsonNode; query: JsonNode;
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
  var valid_603062 = path.getOrDefault("restapi_id")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = nil)
  if valid_603062 != nil:
    section.add "restapi_id", valid_603062
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
  var valid_603063 = header.getOrDefault("X-Amz-Date")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Date", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Security-Token")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Security-Token", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Content-Sha256", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Algorithm")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Algorithm", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Signature")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Signature", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-SignedHeaders", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Credential")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Credential", valid_603069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_CreateAuthorizer_603059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"))
  result = hook(call_603071, url, valid)

proc call*(call_603072: Call_CreateAuthorizer_603059; body: JsonNode;
          restapiId: string): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603073 = newJObject()
  var body_603074 = newJObject()
  if body != nil:
    body_603074 = body
  add(path_603073, "restapi_id", newJString(restapiId))
  result = call_603072.call(path_603073, nil, nil, nil, body_603074)

var createAuthorizer* = Call_CreateAuthorizer_603059(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_603060, base: "/",
    url: url_CreateAuthorizer_603061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_603028 = ref object of OpenApiRestCall_602417
proc url_GetAuthorizers_603030(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetAuthorizers_603029(path: JsonNode; query: JsonNode;
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
  var valid_603045 = path.getOrDefault("restapi_id")
  valid_603045 = validateParameter(valid_603045, JString, required = true,
                                 default = nil)
  if valid_603045 != nil:
    section.add "restapi_id", valid_603045
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603046 = query.getOrDefault("position")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "position", valid_603046
  var valid_603047 = query.getOrDefault("limit")
  valid_603047 = validateParameter(valid_603047, JInt, required = false, default = nil)
  if valid_603047 != nil:
    section.add "limit", valid_603047
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
  var valid_603048 = header.getOrDefault("X-Amz-Date")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Date", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Security-Token")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Security-Token", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Content-Sha256", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Algorithm")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Algorithm", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Signature")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Signature", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-SignedHeaders", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Credential")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Credential", valid_603054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603055: Call_GetAuthorizers_603028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_603055.validator(path, query, header, formData, body)
  let scheme = call_603055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603055.url(scheme.get, call_603055.host, call_603055.base,
                         call_603055.route, valid.getOrDefault("path"))
  result = hook(call_603055, url, valid)

proc call*(call_603056: Call_GetAuthorizers_603028; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603057 = newJObject()
  var query_603058 = newJObject()
  add(query_603058, "position", newJString(position))
  add(query_603058, "limit", newJInt(limit))
  add(path_603057, "restapi_id", newJString(restapiId))
  result = call_603056.call(path_603057, query_603058, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_603028(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_603029, base: "/", url: url_GetAuthorizers_603030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_603092 = ref object of OpenApiRestCall_602417
proc url_CreateBasePathMapping_603094(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name"),
               (kind: ConstantSegment, value: "/basepathmappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateBasePathMapping_603093(path: JsonNode; query: JsonNode;
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
  var valid_603095 = path.getOrDefault("domain_name")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "domain_name", valid_603095
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
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Content-Sha256", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Algorithm")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Algorithm", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Credential")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Credential", valid_603102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603104: Call_CreateBasePathMapping_603092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"))
  result = hook(call_603104, url, valid)

proc call*(call_603105: Call_CreateBasePathMapping_603092; domainName: string;
          body: JsonNode): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  ##   body: JObject (required)
  var path_603106 = newJObject()
  var body_603107 = newJObject()
  add(path_603106, "domain_name", newJString(domainName))
  if body != nil:
    body_603107 = body
  result = call_603105.call(path_603106, nil, nil, nil, body_603107)

var createBasePathMapping* = Call_CreateBasePathMapping_603092(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_603093, base: "/",
    url: url_CreateBasePathMapping_603094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_603075 = ref object of OpenApiRestCall_602417
proc url_GetBasePathMappings_603077(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name"),
               (kind: ConstantSegment, value: "/basepathmappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBasePathMappings_603076(path: JsonNode; query: JsonNode;
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
  var valid_603078 = path.getOrDefault("domain_name")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = nil)
  if valid_603078 != nil:
    section.add "domain_name", valid_603078
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603079 = query.getOrDefault("position")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "position", valid_603079
  var valid_603080 = query.getOrDefault("limit")
  valid_603080 = validateParameter(valid_603080, JInt, required = false, default = nil)
  if valid_603080 != nil:
    section.add "limit", valid_603080
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
  var valid_603081 = header.getOrDefault("X-Amz-Date")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Date", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Security-Token")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Security-Token", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Content-Sha256", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Algorithm")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Algorithm", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Signature")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Signature", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-SignedHeaders", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Credential")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Credential", valid_603087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_GetBasePathMappings_603075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"))
  result = hook(call_603088, url, valid)

proc call*(call_603089: Call_GetBasePathMappings_603075; domainName: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_603090 = newJObject()
  var query_603091 = newJObject()
  add(path_603090, "domain_name", newJString(domainName))
  add(query_603091, "position", newJString(position))
  add(query_603091, "limit", newJInt(limit))
  result = call_603089.call(path_603090, query_603091, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_603075(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_603076, base: "/",
    url: url_GetBasePathMappings_603077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_603125 = ref object of OpenApiRestCall_602417
proc url_CreateDeployment_603127(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateDeployment_603126(path: JsonNode; query: JsonNode;
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
  var valid_603128 = path.getOrDefault("restapi_id")
  valid_603128 = validateParameter(valid_603128, JString, required = true,
                                 default = nil)
  if valid_603128 != nil:
    section.add "restapi_id", valid_603128
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
  var valid_603129 = header.getOrDefault("X-Amz-Date")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Date", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Security-Token")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Security-Token", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Content-Sha256", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Algorithm")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Algorithm", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Signature")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Signature", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-SignedHeaders", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Credential")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Credential", valid_603135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603137: Call_CreateDeployment_603125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_603137.validator(path, query, header, formData, body)
  let scheme = call_603137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603137.url(scheme.get, call_603137.host, call_603137.base,
                         call_603137.route, valid.getOrDefault("path"))
  result = hook(call_603137, url, valid)

proc call*(call_603138: Call_CreateDeployment_603125; body: JsonNode;
          restapiId: string): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603139 = newJObject()
  var body_603140 = newJObject()
  if body != nil:
    body_603140 = body
  add(path_603139, "restapi_id", newJString(restapiId))
  result = call_603138.call(path_603139, nil, nil, nil, body_603140)

var createDeployment* = Call_CreateDeployment_603125(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_603126, base: "/",
    url: url_CreateDeployment_603127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_603108 = ref object of OpenApiRestCall_602417
proc url_GetDeployments_603110(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDeployments_603109(path: JsonNode; query: JsonNode;
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
  var valid_603111 = path.getOrDefault("restapi_id")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "restapi_id", valid_603111
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603112 = query.getOrDefault("position")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "position", valid_603112
  var valid_603113 = query.getOrDefault("limit")
  valid_603113 = validateParameter(valid_603113, JInt, required = false, default = nil)
  if valid_603113 != nil:
    section.add "limit", valid_603113
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
  var valid_603114 = header.getOrDefault("X-Amz-Date")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Date", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Security-Token")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Security-Token", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Content-Sha256", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Algorithm")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Algorithm", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Signature")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Signature", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-SignedHeaders", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Credential")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Credential", valid_603120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603121: Call_GetDeployments_603108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_603121.validator(path, query, header, formData, body)
  let scheme = call_603121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603121.url(scheme.get, call_603121.host, call_603121.base,
                         call_603121.route, valid.getOrDefault("path"))
  result = hook(call_603121, url, valid)

proc call*(call_603122: Call_GetDeployments_603108; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603123 = newJObject()
  var query_603124 = newJObject()
  add(query_603124, "position", newJString(position))
  add(query_603124, "limit", newJInt(limit))
  add(path_603123, "restapi_id", newJString(restapiId))
  result = call_603122.call(path_603123, query_603124, nil, nil, nil)

var getDeployments* = Call_GetDeployments_603108(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_603109, base: "/", url: url_GetDeployments_603110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_603175 = ref object of OpenApiRestCall_602417
proc url_ImportDocumentationParts_603177(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ImportDocumentationParts_603176(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603178 = path.getOrDefault("restapi_id")
  valid_603178 = validateParameter(valid_603178, JString, required = true,
                                 default = nil)
  if valid_603178 != nil:
    section.add "restapi_id", valid_603178
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  section = newJObject()
  var valid_603179 = query.getOrDefault("mode")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = newJString("merge"))
  if valid_603179 != nil:
    section.add "mode", valid_603179
  var valid_603180 = query.getOrDefault("failonwarnings")
  valid_603180 = validateParameter(valid_603180, JBool, required = false, default = nil)
  if valid_603180 != nil:
    section.add "failonwarnings", valid_603180
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
  var valid_603181 = header.getOrDefault("X-Amz-Date")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Date", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Security-Token")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Security-Token", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_ImportDocumentationParts_603175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_ImportDocumentationParts_603175; body: JsonNode;
          restapiId: string; mode: string = "merge"; failonwarnings: bool = false): Recallable =
  ## importDocumentationParts
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603191 = newJObject()
  var query_603192 = newJObject()
  var body_603193 = newJObject()
  add(query_603192, "mode", newJString(mode))
  add(query_603192, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_603193 = body
  add(path_603191, "restapi_id", newJString(restapiId))
  result = call_603190.call(path_603191, query_603192, nil, nil, body_603193)

var importDocumentationParts* = Call_ImportDocumentationParts_603175(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_603176, base: "/",
    url: url_ImportDocumentationParts_603177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_603194 = ref object of OpenApiRestCall_602417
proc url_CreateDocumentationPart_603196(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateDocumentationPart_603195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603197 = path.getOrDefault("restapi_id")
  valid_603197 = validateParameter(valid_603197, JString, required = true,
                                 default = nil)
  if valid_603197 != nil:
    section.add "restapi_id", valid_603197
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
  var valid_603198 = header.getOrDefault("X-Amz-Date")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Date", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Security-Token")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Security-Token", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Content-Sha256", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Algorithm")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Algorithm", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Signature")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Signature", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-SignedHeaders", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Credential")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Credential", valid_603204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603206: Call_CreateDocumentationPart_603194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603206.validator(path, query, header, formData, body)
  let scheme = call_603206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603206.url(scheme.get, call_603206.host, call_603206.base,
                         call_603206.route, valid.getOrDefault("path"))
  result = hook(call_603206, url, valid)

proc call*(call_603207: Call_CreateDocumentationPart_603194; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationPart
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603208 = newJObject()
  var body_603209 = newJObject()
  if body != nil:
    body_603209 = body
  add(path_603208, "restapi_id", newJString(restapiId))
  result = call_603207.call(path_603208, nil, nil, nil, body_603209)

var createDocumentationPart* = Call_CreateDocumentationPart_603194(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_603195, base: "/",
    url: url_CreateDocumentationPart_603196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_603141 = ref object of OpenApiRestCall_602417
proc url_GetDocumentationParts_603143(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/parts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDocumentationParts_603142(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603144 = path.getOrDefault("restapi_id")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "restapi_id", valid_603144
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
  var valid_603158 = query.getOrDefault("type")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = newJString("API"))
  if valid_603158 != nil:
    section.add "type", valid_603158
  var valid_603159 = query.getOrDefault("path")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "path", valid_603159
  var valid_603160 = query.getOrDefault("locationStatus")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_603160 != nil:
    section.add "locationStatus", valid_603160
  var valid_603161 = query.getOrDefault("name")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "name", valid_603161
  var valid_603162 = query.getOrDefault("position")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "position", valid_603162
  var valid_603163 = query.getOrDefault("limit")
  valid_603163 = validateParameter(valid_603163, JInt, required = false, default = nil)
  if valid_603163 != nil:
    section.add "limit", valid_603163
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
  var valid_603164 = header.getOrDefault("X-Amz-Date")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Date", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Security-Token")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Security-Token", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Content-Sha256", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Algorithm")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Algorithm", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-SignedHeaders", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Credential")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Credential", valid_603170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_GetDocumentationParts_603141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_GetDocumentationParts_603141; restapiId: string;
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
  var path_603173 = newJObject()
  var query_603174 = newJObject()
  add(query_603174, "type", newJString(`type`))
  add(query_603174, "path", newJString(path))
  add(query_603174, "locationStatus", newJString(locationStatus))
  add(query_603174, "name", newJString(name))
  add(query_603174, "position", newJString(position))
  add(query_603174, "limit", newJInt(limit))
  add(path_603173, "restapi_id", newJString(restapiId))
  result = call_603172.call(path_603173, query_603174, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_603141(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_603142, base: "/",
    url: url_GetDocumentationParts_603143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_603227 = ref object of OpenApiRestCall_602417
proc url_CreateDocumentationVersion_603229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateDocumentationVersion_603228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603230 = path.getOrDefault("restapi_id")
  valid_603230 = validateParameter(valid_603230, JString, required = true,
                                 default = nil)
  if valid_603230 != nil:
    section.add "restapi_id", valid_603230
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
  var valid_603231 = header.getOrDefault("X-Amz-Date")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Date", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Security-Token")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Security-Token", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Content-Sha256", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Algorithm")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Algorithm", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Signature")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Signature", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-SignedHeaders", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Credential")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Credential", valid_603237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603239: Call_CreateDocumentationVersion_603227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_CreateDocumentationVersion_603227; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationVersion
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603241 = newJObject()
  var body_603242 = newJObject()
  if body != nil:
    body_603242 = body
  add(path_603241, "restapi_id", newJString(restapiId))
  result = call_603240.call(path_603241, nil, nil, nil, body_603242)

var createDocumentationVersion* = Call_CreateDocumentationVersion_603227(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_603228, base: "/",
    url: url_CreateDocumentationVersion_603229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_603210 = ref object of OpenApiRestCall_602417
proc url_GetDocumentationVersions_603212(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/documentation/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDocumentationVersions_603211(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603213 = path.getOrDefault("restapi_id")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "restapi_id", valid_603213
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603214 = query.getOrDefault("position")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "position", valid_603214
  var valid_603215 = query.getOrDefault("limit")
  valid_603215 = validateParameter(valid_603215, JInt, required = false, default = nil)
  if valid_603215 != nil:
    section.add "limit", valid_603215
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
  var valid_603216 = header.getOrDefault("X-Amz-Date")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Date", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Security-Token")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Security-Token", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Content-Sha256", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Algorithm")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Algorithm", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Signature")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Signature", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-SignedHeaders", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Credential")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Credential", valid_603222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603223: Call_GetDocumentationVersions_603210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603223.validator(path, query, header, formData, body)
  let scheme = call_603223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603223.url(scheme.get, call_603223.host, call_603223.base,
                         call_603223.route, valid.getOrDefault("path"))
  result = hook(call_603223, url, valid)

proc call*(call_603224: Call_GetDocumentationVersions_603210; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationVersions
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603225 = newJObject()
  var query_603226 = newJObject()
  add(query_603226, "position", newJString(position))
  add(query_603226, "limit", newJInt(limit))
  add(path_603225, "restapi_id", newJString(restapiId))
  result = call_603224.call(path_603225, query_603226, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_603210(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_603211, base: "/",
    url: url_GetDocumentationVersions_603212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_603258 = ref object of OpenApiRestCall_602417
proc url_CreateDomainName_603260(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDomainName_603259(path: JsonNode; query: JsonNode;
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
  var valid_603261 = header.getOrDefault("X-Amz-Date")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Date", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Security-Token")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Security-Token", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Content-Sha256", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Algorithm")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Algorithm", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Signature")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Signature", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-SignedHeaders", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Credential")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Credential", valid_603267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603269: Call_CreateDomainName_603258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_603269.validator(path, query, header, formData, body)
  let scheme = call_603269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603269.url(scheme.get, call_603269.host, call_603269.base,
                         call_603269.route, valid.getOrDefault("path"))
  result = hook(call_603269, url, valid)

proc call*(call_603270: Call_CreateDomainName_603258; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_603271 = newJObject()
  if body != nil:
    body_603271 = body
  result = call_603270.call(nil, nil, nil, nil, body_603271)

var createDomainName* = Call_CreateDomainName_603258(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_603259, base: "/",
    url: url_CreateDomainName_603260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_603243 = ref object of OpenApiRestCall_602417
proc url_GetDomainNames_603245(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainNames_603244(path: JsonNode; query: JsonNode;
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
  var valid_603246 = query.getOrDefault("position")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "position", valid_603246
  var valid_603247 = query.getOrDefault("limit")
  valid_603247 = validateParameter(valid_603247, JInt, required = false, default = nil)
  if valid_603247 != nil:
    section.add "limit", valid_603247
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
  var valid_603248 = header.getOrDefault("X-Amz-Date")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Date", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Security-Token")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Security-Token", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Content-Sha256", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Algorithm")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Algorithm", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Signature")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Signature", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-SignedHeaders", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Credential")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Credential", valid_603254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603255: Call_GetDomainNames_603243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_603255.validator(path, query, header, formData, body)
  let scheme = call_603255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603255.url(scheme.get, call_603255.host, call_603255.base,
                         call_603255.route, valid.getOrDefault("path"))
  result = hook(call_603255, url, valid)

proc call*(call_603256: Call_GetDomainNames_603243; position: string = "";
          limit: int = 0): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603257 = newJObject()
  add(query_603257, "position", newJString(position))
  add(query_603257, "limit", newJInt(limit))
  result = call_603256.call(nil, query_603257, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_603243(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_603244, base: "/",
    url: url_GetDomainNames_603245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_603289 = ref object of OpenApiRestCall_602417
proc url_CreateModel_603291(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateModel_603290(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603292 = path.getOrDefault("restapi_id")
  valid_603292 = validateParameter(valid_603292, JString, required = true,
                                 default = nil)
  if valid_603292 != nil:
    section.add "restapi_id", valid_603292
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
  var valid_603293 = header.getOrDefault("X-Amz-Date")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Date", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Security-Token")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Security-Token", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Content-Sha256", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Algorithm")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Algorithm", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Signature")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Signature", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-SignedHeaders", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Credential")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Credential", valid_603299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603301: Call_CreateModel_603289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_603301.validator(path, query, header, formData, body)
  let scheme = call_603301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603301.url(scheme.get, call_603301.host, call_603301.base,
                         call_603301.route, valid.getOrDefault("path"))
  result = hook(call_603301, url, valid)

proc call*(call_603302: Call_CreateModel_603289; body: JsonNode; restapiId: string): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  var path_603303 = newJObject()
  var body_603304 = newJObject()
  if body != nil:
    body_603304 = body
  add(path_603303, "restapi_id", newJString(restapiId))
  result = call_603302.call(path_603303, nil, nil, nil, body_603304)

var createModel* = Call_CreateModel_603289(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_603290,
                                        base: "/", url: url_CreateModel_603291,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_603272 = ref object of OpenApiRestCall_602417
proc url_GetModels_603274(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetModels_603273(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603275 = path.getOrDefault("restapi_id")
  valid_603275 = validateParameter(valid_603275, JString, required = true,
                                 default = nil)
  if valid_603275 != nil:
    section.add "restapi_id", valid_603275
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603276 = query.getOrDefault("position")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "position", valid_603276
  var valid_603277 = query.getOrDefault("limit")
  valid_603277 = validateParameter(valid_603277, JInt, required = false, default = nil)
  if valid_603277 != nil:
    section.add "limit", valid_603277
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
  var valid_603278 = header.getOrDefault("X-Amz-Date")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Date", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Security-Token")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Security-Token", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Content-Sha256", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Algorithm")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Algorithm", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Signature")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Signature", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-SignedHeaders", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Credential")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Credential", valid_603284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603285: Call_GetModels_603272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_603285.validator(path, query, header, formData, body)
  let scheme = call_603285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603285.url(scheme.get, call_603285.host, call_603285.base,
                         call_603285.route, valid.getOrDefault("path"))
  result = hook(call_603285, url, valid)

proc call*(call_603286: Call_GetModels_603272; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603287 = newJObject()
  var query_603288 = newJObject()
  add(query_603288, "position", newJString(position))
  add(query_603288, "limit", newJInt(limit))
  add(path_603287, "restapi_id", newJString(restapiId))
  result = call_603286.call(path_603287, query_603288, nil, nil, nil)

var getModels* = Call_GetModels_603272(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_603273,
                                    base: "/", url: url_GetModels_603274,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_603322 = ref object of OpenApiRestCall_602417
proc url_CreateRequestValidator_603324(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/requestvalidators")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateRequestValidator_603323(path: JsonNode; query: JsonNode;
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
  var valid_603325 = path.getOrDefault("restapi_id")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "restapi_id", valid_603325
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
  var valid_603326 = header.getOrDefault("X-Amz-Date")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Date", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Security-Token")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Security-Token", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Content-Sha256", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Algorithm")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Algorithm", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Signature")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Signature", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Credential")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Credential", valid_603332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603334: Call_CreateRequestValidator_603322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_603334.validator(path, query, header, formData, body)
  let scheme = call_603334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603334.url(scheme.get, call_603334.host, call_603334.base,
                         call_603334.route, valid.getOrDefault("path"))
  result = hook(call_603334, url, valid)

proc call*(call_603335: Call_CreateRequestValidator_603322; body: JsonNode;
          restapiId: string): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603336 = newJObject()
  var body_603337 = newJObject()
  if body != nil:
    body_603337 = body
  add(path_603336, "restapi_id", newJString(restapiId))
  result = call_603335.call(path_603336, nil, nil, nil, body_603337)

var createRequestValidator* = Call_CreateRequestValidator_603322(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_603323, base: "/",
    url: url_CreateRequestValidator_603324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_603305 = ref object of OpenApiRestCall_602417
proc url_GetRequestValidators_603307(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/requestvalidators")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetRequestValidators_603306(path: JsonNode; query: JsonNode;
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
  var valid_603308 = path.getOrDefault("restapi_id")
  valid_603308 = validateParameter(valid_603308, JString, required = true,
                                 default = nil)
  if valid_603308 != nil:
    section.add "restapi_id", valid_603308
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603309 = query.getOrDefault("position")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "position", valid_603309
  var valid_603310 = query.getOrDefault("limit")
  valid_603310 = validateParameter(valid_603310, JInt, required = false, default = nil)
  if valid_603310 != nil:
    section.add "limit", valid_603310
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
  var valid_603311 = header.getOrDefault("X-Amz-Date")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Date", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Security-Token")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Security-Token", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Content-Sha256", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Algorithm")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Algorithm", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Signature")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Signature", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-SignedHeaders", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Credential")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Credential", valid_603317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603318: Call_GetRequestValidators_603305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_603318.validator(path, query, header, formData, body)
  let scheme = call_603318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603318.url(scheme.get, call_603318.host, call_603318.base,
                         call_603318.route, valid.getOrDefault("path"))
  result = hook(call_603318, url, valid)

proc call*(call_603319: Call_GetRequestValidators_603305; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603320 = newJObject()
  var query_603321 = newJObject()
  add(query_603321, "position", newJString(position))
  add(query_603321, "limit", newJInt(limit))
  add(path_603320, "restapi_id", newJString(restapiId))
  result = call_603319.call(path_603320, query_603321, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_603305(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_603306, base: "/",
    url: url_GetRequestValidators_603307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_603338 = ref object of OpenApiRestCall_602417
proc url_CreateResource_603340(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateResource_603339(path: JsonNode; query: JsonNode;
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
  var valid_603341 = path.getOrDefault("parent_id")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = nil)
  if valid_603341 != nil:
    section.add "parent_id", valid_603341
  var valid_603342 = path.getOrDefault("restapi_id")
  valid_603342 = validateParameter(valid_603342, JString, required = true,
                                 default = nil)
  if valid_603342 != nil:
    section.add "restapi_id", valid_603342
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
  var valid_603343 = header.getOrDefault("X-Amz-Date")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Date", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Security-Token")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Security-Token", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Content-Sha256", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Algorithm")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Algorithm", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Signature")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Signature", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-SignedHeaders", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Credential")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Credential", valid_603349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_CreateResource_603338; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_CreateResource_603338; parentId: string; body: JsonNode;
          restapiId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603353 = newJObject()
  var body_603354 = newJObject()
  add(path_603353, "parent_id", newJString(parentId))
  if body != nil:
    body_603354 = body
  add(path_603353, "restapi_id", newJString(restapiId))
  result = call_603352.call(path_603353, nil, nil, nil, body_603354)

var createResource* = Call_CreateResource_603338(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_603339, base: "/", url: url_CreateResource_603340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_603370 = ref object of OpenApiRestCall_602417
proc url_CreateRestApi_603372(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRestApi_603371(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603373 = header.getOrDefault("X-Amz-Date")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Date", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Security-Token")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Security-Token", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Content-Sha256", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Algorithm")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Algorithm", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Signature")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Signature", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-SignedHeaders", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Credential")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Credential", valid_603379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_CreateRestApi_603370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"))
  result = hook(call_603381, url, valid)

proc call*(call_603382: Call_CreateRestApi_603370; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_603383 = newJObject()
  if body != nil:
    body_603383 = body
  result = call_603382.call(nil, nil, nil, nil, body_603383)

var createRestApi* = Call_CreateRestApi_603370(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_603371, base: "/", url: url_CreateRestApi_603372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_603355 = ref object of OpenApiRestCall_602417
proc url_GetRestApis_603357(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestApis_603356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603358 = query.getOrDefault("position")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "position", valid_603358
  var valid_603359 = query.getOrDefault("limit")
  valid_603359 = validateParameter(valid_603359, JInt, required = false, default = nil)
  if valid_603359 != nil:
    section.add "limit", valid_603359
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
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Content-Sha256", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Algorithm")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Algorithm", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Signature")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Signature", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-SignedHeaders", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Credential")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Credential", valid_603366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_GetRestApis_603355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_GetRestApis_603355; position: string = ""; limit: int = 0): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603369 = newJObject()
  add(query_603369, "position", newJString(position))
  add(query_603369, "limit", newJInt(limit))
  result = call_603368.call(nil, query_603369, nil, nil, nil)

var getRestApis* = Call_GetRestApis_603355(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_603356,
                                        base: "/", url: url_GetRestApis_603357,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_603400 = ref object of OpenApiRestCall_602417
proc url_CreateStage_603402(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateStage_603401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603403 = path.getOrDefault("restapi_id")
  valid_603403 = validateParameter(valid_603403, JString, required = true,
                                 default = nil)
  if valid_603403 != nil:
    section.add "restapi_id", valid_603403
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
  var valid_603404 = header.getOrDefault("X-Amz-Date")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Date", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Security-Token")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Security-Token", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Content-Sha256", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Algorithm")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Algorithm", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Signature")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Signature", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-SignedHeaders", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Credential")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Credential", valid_603410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_CreateStage_603400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"))
  result = hook(call_603412, url, valid)

proc call*(call_603413: Call_CreateStage_603400; body: JsonNode; restapiId: string): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603414 = newJObject()
  var body_603415 = newJObject()
  if body != nil:
    body_603415 = body
  add(path_603414, "restapi_id", newJString(restapiId))
  result = call_603413.call(path_603414, nil, nil, nil, body_603415)

var createStage* = Call_CreateStage_603400(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_603401,
                                        base: "/", url: url_CreateStage_603402,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_603384 = ref object of OpenApiRestCall_602417
proc url_GetStages_603386(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetStages_603385(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603387 = path.getOrDefault("restapi_id")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = nil)
  if valid_603387 != nil:
    section.add "restapi_id", valid_603387
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_603388 = query.getOrDefault("deploymentId")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "deploymentId", valid_603388
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
  var valid_603389 = header.getOrDefault("X-Amz-Date")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Date", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Security-Token")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Security-Token", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Content-Sha256", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Signature")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Signature", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-SignedHeaders", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Credential")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Credential", valid_603395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603396: Call_GetStages_603384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_603396.validator(path, query, header, formData, body)
  let scheme = call_603396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603396.url(scheme.get, call_603396.host, call_603396.base,
                         call_603396.route, valid.getOrDefault("path"))
  result = hook(call_603396, url, valid)

proc call*(call_603397: Call_GetStages_603384; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603398 = newJObject()
  var query_603399 = newJObject()
  add(query_603399, "deploymentId", newJString(deploymentId))
  add(path_603398, "restapi_id", newJString(restapiId))
  result = call_603397.call(path_603398, query_603399, nil, nil, nil)

var getStages* = Call_GetStages_603384(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_603385,
                                    base: "/", url: url_GetStages_603386,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_603432 = ref object of OpenApiRestCall_602417
proc url_CreateUsagePlan_603434(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUsagePlan_603433(path: JsonNode; query: JsonNode;
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
  var valid_603435 = header.getOrDefault("X-Amz-Date")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Date", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Content-Sha256", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Algorithm")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Algorithm", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Signature")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Signature", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-SignedHeaders", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Credential")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Credential", valid_603441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603443: Call_CreateUsagePlan_603432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_603443.validator(path, query, header, formData, body)
  let scheme = call_603443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603443.url(scheme.get, call_603443.host, call_603443.base,
                         call_603443.route, valid.getOrDefault("path"))
  result = hook(call_603443, url, valid)

proc call*(call_603444: Call_CreateUsagePlan_603432; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_603445 = newJObject()
  if body != nil:
    body_603445 = body
  result = call_603444.call(nil, nil, nil, nil, body_603445)

var createUsagePlan* = Call_CreateUsagePlan_603432(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_603433, base: "/",
    url: url_CreateUsagePlan_603434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_603416 = ref object of OpenApiRestCall_602417
proc url_GetUsagePlans_603418(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUsagePlans_603417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603419 = query.getOrDefault("keyId")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "keyId", valid_603419
  var valid_603420 = query.getOrDefault("position")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "position", valid_603420
  var valid_603421 = query.getOrDefault("limit")
  valid_603421 = validateParameter(valid_603421, JInt, required = false, default = nil)
  if valid_603421 != nil:
    section.add "limit", valid_603421
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
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_GetUsagePlans_603416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_GetUsagePlans_603416; keyId: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603431 = newJObject()
  add(query_603431, "keyId", newJString(keyId))
  add(query_603431, "position", newJString(position))
  add(query_603431, "limit", newJInt(limit))
  result = call_603430.call(nil, query_603431, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_603416(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_603417, base: "/",
    url: url_GetUsagePlans_603418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_603464 = ref object of OpenApiRestCall_602417
proc url_CreateUsagePlanKey_603466(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/keys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateUsagePlanKey_603465(path: JsonNode; query: JsonNode;
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
  var valid_603467 = path.getOrDefault("usageplanId")
  valid_603467 = validateParameter(valid_603467, JString, required = true,
                                 default = nil)
  if valid_603467 != nil:
    section.add "usageplanId", valid_603467
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
  var valid_603468 = header.getOrDefault("X-Amz-Date")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Date", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Security-Token")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Security-Token", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Content-Sha256", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Algorithm")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Algorithm", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Signature")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Signature", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-SignedHeaders", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Credential")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Credential", valid_603474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603476: Call_CreateUsagePlanKey_603464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_603476.validator(path, query, header, formData, body)
  let scheme = call_603476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603476.url(scheme.get, call_603476.host, call_603476.base,
                         call_603476.route, valid.getOrDefault("path"))
  result = hook(call_603476, url, valid)

proc call*(call_603477: Call_CreateUsagePlanKey_603464; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_603478 = newJObject()
  var body_603479 = newJObject()
  add(path_603478, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_603479 = body
  result = call_603477.call(path_603478, nil, nil, nil, body_603479)

var createUsagePlanKey* = Call_CreateUsagePlanKey_603464(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_603465, base: "/",
    url: url_CreateUsagePlanKey_603466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_603446 = ref object of OpenApiRestCall_602417
proc url_GetUsagePlanKeys_603448(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/keys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUsagePlanKeys_603447(path: JsonNode; query: JsonNode;
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
  var valid_603449 = path.getOrDefault("usageplanId")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = nil)
  if valid_603449 != nil:
    section.add "usageplanId", valid_603449
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603450 = query.getOrDefault("name")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "name", valid_603450
  var valid_603451 = query.getOrDefault("position")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "position", valid_603451
  var valid_603452 = query.getOrDefault("limit")
  valid_603452 = validateParameter(valid_603452, JInt, required = false, default = nil)
  if valid_603452 != nil:
    section.add "limit", valid_603452
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
  var valid_603453 = header.getOrDefault("X-Amz-Date")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Date", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Security-Token")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Security-Token", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Content-Sha256", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Algorithm")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Algorithm", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Signature")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Signature", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-SignedHeaders", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Credential")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Credential", valid_603459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603460: Call_GetUsagePlanKeys_603446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"))
  result = hook(call_603460, url, valid)

proc call*(call_603461: Call_GetUsagePlanKeys_603446; usageplanId: string;
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
  var path_603462 = newJObject()
  var query_603463 = newJObject()
  add(path_603462, "usageplanId", newJString(usageplanId))
  add(query_603463, "name", newJString(name))
  add(query_603463, "position", newJString(position))
  add(query_603463, "limit", newJInt(limit))
  result = call_603461.call(path_603462, query_603463, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_603446(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_603447,
    base: "/", url: url_GetUsagePlanKeys_603448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_603495 = ref object of OpenApiRestCall_602417
proc url_CreateVpcLink_603497(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateVpcLink_603496(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603498 = header.getOrDefault("X-Amz-Date")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Date", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Security-Token")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Security-Token", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Content-Sha256", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Algorithm")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Algorithm", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Signature")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Signature", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-SignedHeaders", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Credential")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Credential", valid_603504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603506: Call_CreateVpcLink_603495; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_603506.validator(path, query, header, formData, body)
  let scheme = call_603506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603506.url(scheme.get, call_603506.host, call_603506.base,
                         call_603506.route, valid.getOrDefault("path"))
  result = hook(call_603506, url, valid)

proc call*(call_603507: Call_CreateVpcLink_603495; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_603508 = newJObject()
  if body != nil:
    body_603508 = body
  result = call_603507.call(nil, nil, nil, nil, body_603508)

var createVpcLink* = Call_CreateVpcLink_603495(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_603496, base: "/", url: url_CreateVpcLink_603497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_603480 = ref object of OpenApiRestCall_602417
proc url_GetVpcLinks_603482(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetVpcLinks_603481(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603483 = query.getOrDefault("position")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "position", valid_603483
  var valid_603484 = query.getOrDefault("limit")
  valid_603484 = validateParameter(valid_603484, JInt, required = false, default = nil)
  if valid_603484 != nil:
    section.add "limit", valid_603484
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
  var valid_603485 = header.getOrDefault("X-Amz-Date")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Date", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Security-Token")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Security-Token", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Content-Sha256", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Algorithm")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Algorithm", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Signature")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Signature", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-SignedHeaders", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Credential")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Credential", valid_603491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603492: Call_GetVpcLinks_603480; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_603492.validator(path, query, header, formData, body)
  let scheme = call_603492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603492.url(scheme.get, call_603492.host, call_603492.base,
                         call_603492.route, valid.getOrDefault("path"))
  result = hook(call_603492, url, valid)

proc call*(call_603493: Call_GetVpcLinks_603480; position: string = ""; limit: int = 0): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603494 = newJObject()
  add(query_603494, "position", newJString(position))
  add(query_603494, "limit", newJInt(limit))
  result = call_603493.call(nil, query_603494, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_603480(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_603481,
                                        base: "/", url: url_GetVpcLinks_603482,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_603509 = ref object of OpenApiRestCall_602417
proc url_GetApiKey_603511(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetApiKey_603510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603512 = path.getOrDefault("api_Key")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = nil)
  if valid_603512 != nil:
    section.add "api_Key", valid_603512
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_603513 = query.getOrDefault("includeValue")
  valid_603513 = validateParameter(valid_603513, JBool, required = false, default = nil)
  if valid_603513 != nil:
    section.add "includeValue", valid_603513
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
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Content-Sha256", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Signature")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Signature", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-SignedHeaders", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Credential")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Credential", valid_603520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603521: Call_GetApiKey_603509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_603521.validator(path, query, header, formData, body)
  let scheme = call_603521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603521.url(scheme.get, call_603521.host, call_603521.base,
                         call_603521.route, valid.getOrDefault("path"))
  result = hook(call_603521, url, valid)

proc call*(call_603522: Call_GetApiKey_603509; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_603523 = newJObject()
  var query_603524 = newJObject()
  add(query_603524, "includeValue", newJBool(includeValue))
  add(path_603523, "api_Key", newJString(apiKey))
  result = call_603522.call(path_603523, query_603524, nil, nil, nil)

var getApiKey* = Call_GetApiKey_603509(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_603510,
                                    base: "/", url: url_GetApiKey_603511,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_603539 = ref object of OpenApiRestCall_602417
proc url_UpdateApiKey_603541(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateApiKey_603540(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603542 = path.getOrDefault("api_Key")
  valid_603542 = validateParameter(valid_603542, JString, required = true,
                                 default = nil)
  if valid_603542 != nil:
    section.add "api_Key", valid_603542
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
  var valid_603543 = header.getOrDefault("X-Amz-Date")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Date", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Security-Token")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Security-Token", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Content-Sha256", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Algorithm")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Algorithm", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Signature")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Signature", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-SignedHeaders", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Credential")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Credential", valid_603549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603551: Call_UpdateApiKey_603539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_603551.validator(path, query, header, formData, body)
  let scheme = call_603551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603551.url(scheme.get, call_603551.host, call_603551.base,
                         call_603551.route, valid.getOrDefault("path"))
  result = hook(call_603551, url, valid)

proc call*(call_603552: Call_UpdateApiKey_603539; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_603553 = newJObject()
  var body_603554 = newJObject()
  add(path_603553, "api_Key", newJString(apiKey))
  if body != nil:
    body_603554 = body
  result = call_603552.call(path_603553, nil, nil, nil, body_603554)

var updateApiKey* = Call_UpdateApiKey_603539(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_603540, base: "/",
    url: url_UpdateApiKey_603541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_603525 = ref object of OpenApiRestCall_602417
proc url_DeleteApiKey_603527(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteApiKey_603526(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603528 = path.getOrDefault("api_Key")
  valid_603528 = validateParameter(valid_603528, JString, required = true,
                                 default = nil)
  if valid_603528 != nil:
    section.add "api_Key", valid_603528
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
  var valid_603529 = header.getOrDefault("X-Amz-Date")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Date", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Security-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Security-Token", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Content-Sha256", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Algorithm")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Algorithm", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Signature")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Signature", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-SignedHeaders", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Credential")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Credential", valid_603535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603536: Call_DeleteApiKey_603525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_603536.validator(path, query, header, formData, body)
  let scheme = call_603536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603536.url(scheme.get, call_603536.host, call_603536.base,
                         call_603536.route, valid.getOrDefault("path"))
  result = hook(call_603536, url, valid)

proc call*(call_603537: Call_DeleteApiKey_603525; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_603538 = newJObject()
  add(path_603538, "api_Key", newJString(apiKey))
  result = call_603537.call(path_603538, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_603525(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_603526, base: "/",
    url: url_DeleteApiKey_603527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_603570 = ref object of OpenApiRestCall_602417
proc url_TestInvokeAuthorizer_603572(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_TestInvokeAuthorizer_603571(path: JsonNode; query: JsonNode;
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
  var valid_603573 = path.getOrDefault("authorizer_id")
  valid_603573 = validateParameter(valid_603573, JString, required = true,
                                 default = nil)
  if valid_603573 != nil:
    section.add "authorizer_id", valid_603573
  var valid_603574 = path.getOrDefault("restapi_id")
  valid_603574 = validateParameter(valid_603574, JString, required = true,
                                 default = nil)
  if valid_603574 != nil:
    section.add "restapi_id", valid_603574
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
  var valid_603575 = header.getOrDefault("X-Amz-Date")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Date", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Security-Token")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Security-Token", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Content-Sha256", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Algorithm")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Algorithm", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Signature")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Signature", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-SignedHeaders", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Credential")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Credential", valid_603581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603583: Call_TestInvokeAuthorizer_603570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_603583.validator(path, query, header, formData, body)
  let scheme = call_603583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603583.url(scheme.get, call_603583.host, call_603583.base,
                         call_603583.route, valid.getOrDefault("path"))
  result = hook(call_603583, url, valid)

proc call*(call_603584: Call_TestInvokeAuthorizer_603570; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603585 = newJObject()
  var body_603586 = newJObject()
  add(path_603585, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_603586 = body
  add(path_603585, "restapi_id", newJString(restapiId))
  result = call_603584.call(path_603585, nil, nil, nil, body_603586)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_603570(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_603571, base: "/",
    url: url_TestInvokeAuthorizer_603572, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_603555 = ref object of OpenApiRestCall_602417
proc url_GetAuthorizer_603557(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetAuthorizer_603556(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603558 = path.getOrDefault("authorizer_id")
  valid_603558 = validateParameter(valid_603558, JString, required = true,
                                 default = nil)
  if valid_603558 != nil:
    section.add "authorizer_id", valid_603558
  var valid_603559 = path.getOrDefault("restapi_id")
  valid_603559 = validateParameter(valid_603559, JString, required = true,
                                 default = nil)
  if valid_603559 != nil:
    section.add "restapi_id", valid_603559
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
  var valid_603560 = header.getOrDefault("X-Amz-Date")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Date", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Security-Token")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Security-Token", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Content-Sha256", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Algorithm")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Algorithm", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Signature")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Signature", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-SignedHeaders", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Credential")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Credential", valid_603566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603567: Call_GetAuthorizer_603555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603567.validator(path, query, header, formData, body)
  let scheme = call_603567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603567.url(scheme.get, call_603567.host, call_603567.base,
                         call_603567.route, valid.getOrDefault("path"))
  result = hook(call_603567, url, valid)

proc call*(call_603568: Call_GetAuthorizer_603555; authorizerId: string;
          restapiId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603569 = newJObject()
  add(path_603569, "authorizer_id", newJString(authorizerId))
  add(path_603569, "restapi_id", newJString(restapiId))
  result = call_603568.call(path_603569, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_603555(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_603556, base: "/", url: url_GetAuthorizer_603557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_603602 = ref object of OpenApiRestCall_602417
proc url_UpdateAuthorizer_603604(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateAuthorizer_603603(path: JsonNode; query: JsonNode;
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
  var valid_603605 = path.getOrDefault("authorizer_id")
  valid_603605 = validateParameter(valid_603605, JString, required = true,
                                 default = nil)
  if valid_603605 != nil:
    section.add "authorizer_id", valid_603605
  var valid_603606 = path.getOrDefault("restapi_id")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = nil)
  if valid_603606 != nil:
    section.add "restapi_id", valid_603606
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
  var valid_603607 = header.getOrDefault("X-Amz-Date")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Date", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Security-Token")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Security-Token", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Content-Sha256", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Algorithm")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Algorithm", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Signature")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Signature", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-SignedHeaders", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Credential")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Credential", valid_603613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603615: Call_UpdateAuthorizer_603602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603615.validator(path, query, header, formData, body)
  let scheme = call_603615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603615.url(scheme.get, call_603615.host, call_603615.base,
                         call_603615.route, valid.getOrDefault("path"))
  result = hook(call_603615, url, valid)

proc call*(call_603616: Call_UpdateAuthorizer_603602; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603617 = newJObject()
  var body_603618 = newJObject()
  add(path_603617, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_603618 = body
  add(path_603617, "restapi_id", newJString(restapiId))
  result = call_603616.call(path_603617, nil, nil, nil, body_603618)

var updateAuthorizer* = Call_UpdateAuthorizer_603602(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_603603, base: "/",
    url: url_UpdateAuthorizer_603604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_603587 = ref object of OpenApiRestCall_602417
proc url_DeleteAuthorizer_603589(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteAuthorizer_603588(path: JsonNode; query: JsonNode;
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
  var valid_603590 = path.getOrDefault("authorizer_id")
  valid_603590 = validateParameter(valid_603590, JString, required = true,
                                 default = nil)
  if valid_603590 != nil:
    section.add "authorizer_id", valid_603590
  var valid_603591 = path.getOrDefault("restapi_id")
  valid_603591 = validateParameter(valid_603591, JString, required = true,
                                 default = nil)
  if valid_603591 != nil:
    section.add "restapi_id", valid_603591
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
  var valid_603592 = header.getOrDefault("X-Amz-Date")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Date", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Security-Token")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Security-Token", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Content-Sha256", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Algorithm")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Algorithm", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Signature")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Signature", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-SignedHeaders", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Credential")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Credential", valid_603598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603599: Call_DeleteAuthorizer_603587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603599.validator(path, query, header, formData, body)
  let scheme = call_603599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603599.url(scheme.get, call_603599.host, call_603599.base,
                         call_603599.route, valid.getOrDefault("path"))
  result = hook(call_603599, url, valid)

proc call*(call_603600: Call_DeleteAuthorizer_603587; authorizerId: string;
          restapiId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603601 = newJObject()
  add(path_603601, "authorizer_id", newJString(authorizerId))
  add(path_603601, "restapi_id", newJString(restapiId))
  result = call_603600.call(path_603601, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_603587(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_603588, base: "/",
    url: url_DeleteAuthorizer_603589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_603619 = ref object of OpenApiRestCall_602417
proc url_GetBasePathMapping_603621(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBasePathMapping_603620(path: JsonNode; query: JsonNode;
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
  var valid_603622 = path.getOrDefault("base_path")
  valid_603622 = validateParameter(valid_603622, JString, required = true,
                                 default = nil)
  if valid_603622 != nil:
    section.add "base_path", valid_603622
  var valid_603623 = path.getOrDefault("domain_name")
  valid_603623 = validateParameter(valid_603623, JString, required = true,
                                 default = nil)
  if valid_603623 != nil:
    section.add "domain_name", valid_603623
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
  var valid_603624 = header.getOrDefault("X-Amz-Date")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Date", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Security-Token")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Security-Token", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Content-Sha256", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Algorithm")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Algorithm", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Signature")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Signature", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-SignedHeaders", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Credential")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Credential", valid_603630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_GetBasePathMapping_603619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_GetBasePathMapping_603619; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_603633 = newJObject()
  add(path_603633, "base_path", newJString(basePath))
  add(path_603633, "domain_name", newJString(domainName))
  result = call_603632.call(path_603633, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_603619(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_603620, base: "/",
    url: url_GetBasePathMapping_603621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_603649 = ref object of OpenApiRestCall_602417
proc url_UpdateBasePathMapping_603651(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateBasePathMapping_603650(path: JsonNode; query: JsonNode;
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
  var valid_603652 = path.getOrDefault("base_path")
  valid_603652 = validateParameter(valid_603652, JString, required = true,
                                 default = nil)
  if valid_603652 != nil:
    section.add "base_path", valid_603652
  var valid_603653 = path.getOrDefault("domain_name")
  valid_603653 = validateParameter(valid_603653, JString, required = true,
                                 default = nil)
  if valid_603653 != nil:
    section.add "domain_name", valid_603653
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
  var valid_603654 = header.getOrDefault("X-Amz-Date")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Date", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Security-Token")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Security-Token", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Content-Sha256", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Algorithm")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Algorithm", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Signature")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Signature", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-SignedHeaders", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Credential")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Credential", valid_603660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603662: Call_UpdateBasePathMapping_603649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603662.validator(path, query, header, formData, body)
  let scheme = call_603662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603662.url(scheme.get, call_603662.host, call_603662.base,
                         call_603662.route, valid.getOrDefault("path"))
  result = hook(call_603662, url, valid)

proc call*(call_603663: Call_UpdateBasePathMapping_603649; basePath: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  ##   body: JObject (required)
  var path_603664 = newJObject()
  var body_603665 = newJObject()
  add(path_603664, "base_path", newJString(basePath))
  add(path_603664, "domain_name", newJString(domainName))
  if body != nil:
    body_603665 = body
  result = call_603663.call(path_603664, nil, nil, nil, body_603665)

var updateBasePathMapping* = Call_UpdateBasePathMapping_603649(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_603650, base: "/",
    url: url_UpdateBasePathMapping_603651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_603634 = ref object of OpenApiRestCall_602417
proc url_DeleteBasePathMapping_603636(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBasePathMapping_603635(path: JsonNode; query: JsonNode;
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
  var valid_603637 = path.getOrDefault("base_path")
  valid_603637 = validateParameter(valid_603637, JString, required = true,
                                 default = nil)
  if valid_603637 != nil:
    section.add "base_path", valid_603637
  var valid_603638 = path.getOrDefault("domain_name")
  valid_603638 = validateParameter(valid_603638, JString, required = true,
                                 default = nil)
  if valid_603638 != nil:
    section.add "domain_name", valid_603638
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
  var valid_603639 = header.getOrDefault("X-Amz-Date")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Date", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Security-Token")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Security-Token", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Content-Sha256", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Algorithm")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Algorithm", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Signature")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Signature", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-SignedHeaders", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Credential")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Credential", valid_603645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603646: Call_DeleteBasePathMapping_603634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603646.validator(path, query, header, formData, body)
  let scheme = call_603646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603646.url(scheme.get, call_603646.host, call_603646.base,
                         call_603646.route, valid.getOrDefault("path"))
  result = hook(call_603646, url, valid)

proc call*(call_603647: Call_DeleteBasePathMapping_603634; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_603648 = newJObject()
  add(path_603648, "base_path", newJString(basePath))
  add(path_603648, "domain_name", newJString(domainName))
  result = call_603647.call(path_603648, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_603634(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_603635, base: "/",
    url: url_DeleteBasePathMapping_603636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_603666 = ref object of OpenApiRestCall_602417
proc url_GetClientCertificate_603668(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "clientcertificate_id" in path,
        "`clientcertificate_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clientcertificates/"),
               (kind: VariableSegment, value: "clientcertificate_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetClientCertificate_603667(path: JsonNode; query: JsonNode;
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
  var valid_603669 = path.getOrDefault("clientcertificate_id")
  valid_603669 = validateParameter(valid_603669, JString, required = true,
                                 default = nil)
  if valid_603669 != nil:
    section.add "clientcertificate_id", valid_603669
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
  var valid_603670 = header.getOrDefault("X-Amz-Date")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Date", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Security-Token")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Security-Token", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Content-Sha256", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Algorithm")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Algorithm", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Signature")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Signature", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-SignedHeaders", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Credential")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Credential", valid_603676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603677: Call_GetClientCertificate_603666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_603677.validator(path, query, header, formData, body)
  let scheme = call_603677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603677.url(scheme.get, call_603677.host, call_603677.base,
                         call_603677.route, valid.getOrDefault("path"))
  result = hook(call_603677, url, valid)

proc call*(call_603678: Call_GetClientCertificate_603666;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_603679 = newJObject()
  add(path_603679, "clientcertificate_id", newJString(clientcertificateId))
  result = call_603678.call(path_603679, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_603666(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_603667, base: "/",
    url: url_GetClientCertificate_603668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_603694 = ref object of OpenApiRestCall_602417
proc url_UpdateClientCertificate_603696(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "clientcertificate_id" in path,
        "`clientcertificate_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clientcertificates/"),
               (kind: VariableSegment, value: "clientcertificate_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateClientCertificate_603695(path: JsonNode; query: JsonNode;
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
  var valid_603697 = path.getOrDefault("clientcertificate_id")
  valid_603697 = validateParameter(valid_603697, JString, required = true,
                                 default = nil)
  if valid_603697 != nil:
    section.add "clientcertificate_id", valid_603697
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
  var valid_603698 = header.getOrDefault("X-Amz-Date")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Date", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Security-Token")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Security-Token", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Content-Sha256", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Algorithm")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Algorithm", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Signature")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Signature", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-SignedHeaders", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Credential")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Credential", valid_603704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603706: Call_UpdateClientCertificate_603694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_603706.validator(path, query, header, formData, body)
  let scheme = call_603706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603706.url(scheme.get, call_603706.host, call_603706.base,
                         call_603706.route, valid.getOrDefault("path"))
  result = hook(call_603706, url, valid)

proc call*(call_603707: Call_UpdateClientCertificate_603694;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_603708 = newJObject()
  var body_603709 = newJObject()
  add(path_603708, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_603709 = body
  result = call_603707.call(path_603708, nil, nil, nil, body_603709)

var updateClientCertificate* = Call_UpdateClientCertificate_603694(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_603695, base: "/",
    url: url_UpdateClientCertificate_603696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_603680 = ref object of OpenApiRestCall_602417
proc url_DeleteClientCertificate_603682(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "clientcertificate_id" in path,
        "`clientcertificate_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clientcertificates/"),
               (kind: VariableSegment, value: "clientcertificate_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteClientCertificate_603681(path: JsonNode; query: JsonNode;
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
  var valid_603683 = path.getOrDefault("clientcertificate_id")
  valid_603683 = validateParameter(valid_603683, JString, required = true,
                                 default = nil)
  if valid_603683 != nil:
    section.add "clientcertificate_id", valid_603683
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
  var valid_603684 = header.getOrDefault("X-Amz-Date")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Date", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Security-Token")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Security-Token", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Content-Sha256", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Algorithm")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Algorithm", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Signature")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Signature", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-SignedHeaders", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Credential")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Credential", valid_603690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603691: Call_DeleteClientCertificate_603680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_603691.validator(path, query, header, formData, body)
  let scheme = call_603691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603691.url(scheme.get, call_603691.host, call_603691.base,
                         call_603691.route, valid.getOrDefault("path"))
  result = hook(call_603691, url, valid)

proc call*(call_603692: Call_DeleteClientCertificate_603680;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_603693 = newJObject()
  add(path_603693, "clientcertificate_id", newJString(clientcertificateId))
  result = call_603692.call(path_603693, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_603680(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_603681, base: "/",
    url: url_DeleteClientCertificate_603682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_603710 = ref object of OpenApiRestCall_602417
proc url_GetDeployment_603712(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDeployment_603711(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603713 = path.getOrDefault("deployment_id")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "deployment_id", valid_603713
  var valid_603714 = path.getOrDefault("restapi_id")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = nil)
  if valid_603714 != nil:
    section.add "restapi_id", valid_603714
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_603715 = query.getOrDefault("embed")
  valid_603715 = validateParameter(valid_603715, JArray, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "embed", valid_603715
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
  var valid_603716 = header.getOrDefault("X-Amz-Date")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Date", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Security-Token")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Security-Token", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Content-Sha256", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Algorithm")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Algorithm", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Signature")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Signature", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-SignedHeaders", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Credential")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Credential", valid_603722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603723: Call_GetDeployment_603710; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_603723.validator(path, query, header, formData, body)
  let scheme = call_603723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603723.url(scheme.get, call_603723.host, call_603723.base,
                         call_603723.route, valid.getOrDefault("path"))
  result = hook(call_603723, url, valid)

proc call*(call_603724: Call_GetDeployment_603710; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603725 = newJObject()
  var query_603726 = newJObject()
  add(path_603725, "deployment_id", newJString(deploymentId))
  if embed != nil:
    query_603726.add "embed", embed
  add(path_603725, "restapi_id", newJString(restapiId))
  result = call_603724.call(path_603725, query_603726, nil, nil, nil)

var getDeployment* = Call_GetDeployment_603710(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_603711, base: "/", url: url_GetDeployment_603712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_603742 = ref object of OpenApiRestCall_602417
proc url_UpdateDeployment_603744(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateDeployment_603743(path: JsonNode; query: JsonNode;
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
  var valid_603745 = path.getOrDefault("deployment_id")
  valid_603745 = validateParameter(valid_603745, JString, required = true,
                                 default = nil)
  if valid_603745 != nil:
    section.add "deployment_id", valid_603745
  var valid_603746 = path.getOrDefault("restapi_id")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = nil)
  if valid_603746 != nil:
    section.add "restapi_id", valid_603746
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
  var valid_603747 = header.getOrDefault("X-Amz-Date")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Date", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Security-Token")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Security-Token", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Content-Sha256", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Algorithm")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Algorithm", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Signature")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Signature", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-SignedHeaders", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Credential")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Credential", valid_603753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603755: Call_UpdateDeployment_603742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_603755.validator(path, query, header, formData, body)
  let scheme = call_603755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603755.url(scheme.get, call_603755.host, call_603755.base,
                         call_603755.route, valid.getOrDefault("path"))
  result = hook(call_603755, url, valid)

proc call*(call_603756: Call_UpdateDeployment_603742; deploymentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603757 = newJObject()
  var body_603758 = newJObject()
  add(path_603757, "deployment_id", newJString(deploymentId))
  if body != nil:
    body_603758 = body
  add(path_603757, "restapi_id", newJString(restapiId))
  result = call_603756.call(path_603757, nil, nil, nil, body_603758)

var updateDeployment* = Call_UpdateDeployment_603742(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_603743, base: "/",
    url: url_UpdateDeployment_603744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_603727 = ref object of OpenApiRestCall_602417
proc url_DeleteDeployment_603729(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteDeployment_603728(path: JsonNode; query: JsonNode;
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
  var valid_603730 = path.getOrDefault("deployment_id")
  valid_603730 = validateParameter(valid_603730, JString, required = true,
                                 default = nil)
  if valid_603730 != nil:
    section.add "deployment_id", valid_603730
  var valid_603731 = path.getOrDefault("restapi_id")
  valid_603731 = validateParameter(valid_603731, JString, required = true,
                                 default = nil)
  if valid_603731 != nil:
    section.add "restapi_id", valid_603731
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
  var valid_603732 = header.getOrDefault("X-Amz-Date")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Date", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Security-Token")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Security-Token", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Content-Sha256", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Algorithm")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Algorithm", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Signature")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Signature", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-SignedHeaders", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Credential")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Credential", valid_603738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603739: Call_DeleteDeployment_603727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_603739.validator(path, query, header, formData, body)
  let scheme = call_603739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603739.url(scheme.get, call_603739.host, call_603739.base,
                         call_603739.route, valid.getOrDefault("path"))
  result = hook(call_603739, url, valid)

proc call*(call_603740: Call_DeleteDeployment_603727; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603741 = newJObject()
  add(path_603741, "deployment_id", newJString(deploymentId))
  add(path_603741, "restapi_id", newJString(restapiId))
  result = call_603740.call(path_603741, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_603727(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_603728, base: "/",
    url: url_DeleteDeployment_603729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_603759 = ref object of OpenApiRestCall_602417
proc url_GetDocumentationPart_603761(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDocumentationPart_603760(path: JsonNode; query: JsonNode;
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
  var valid_603762 = path.getOrDefault("part_id")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = nil)
  if valid_603762 != nil:
    section.add "part_id", valid_603762
  var valid_603763 = path.getOrDefault("restapi_id")
  valid_603763 = validateParameter(valid_603763, JString, required = true,
                                 default = nil)
  if valid_603763 != nil:
    section.add "restapi_id", valid_603763
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
  var valid_603764 = header.getOrDefault("X-Amz-Date")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Date", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Security-Token")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Security-Token", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Content-Sha256", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Algorithm")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Algorithm", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Signature")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Signature", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-SignedHeaders", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Credential")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Credential", valid_603770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603771: Call_GetDocumentationPart_603759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603771.validator(path, query, header, formData, body)
  let scheme = call_603771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603771.url(scheme.get, call_603771.host, call_603771.base,
                         call_603771.route, valid.getOrDefault("path"))
  result = hook(call_603771, url, valid)

proc call*(call_603772: Call_GetDocumentationPart_603759; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603773 = newJObject()
  add(path_603773, "part_id", newJString(partId))
  add(path_603773, "restapi_id", newJString(restapiId))
  result = call_603772.call(path_603773, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_603759(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_603760, base: "/",
    url: url_GetDocumentationPart_603761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_603789 = ref object of OpenApiRestCall_602417
proc url_UpdateDocumentationPart_603791(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateDocumentationPart_603790(path: JsonNode; query: JsonNode;
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
  var valid_603792 = path.getOrDefault("part_id")
  valid_603792 = validateParameter(valid_603792, JString, required = true,
                                 default = nil)
  if valid_603792 != nil:
    section.add "part_id", valid_603792
  var valid_603793 = path.getOrDefault("restapi_id")
  valid_603793 = validateParameter(valid_603793, JString, required = true,
                                 default = nil)
  if valid_603793 != nil:
    section.add "restapi_id", valid_603793
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
  var valid_603794 = header.getOrDefault("X-Amz-Date")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Date", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Security-Token")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Security-Token", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Content-Sha256", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Algorithm")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Algorithm", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Signature")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Signature", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-SignedHeaders", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Credential")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Credential", valid_603800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603802: Call_UpdateDocumentationPart_603789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603802.validator(path, query, header, formData, body)
  let scheme = call_603802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603802.url(scheme.get, call_603802.host, call_603802.base,
                         call_603802.route, valid.getOrDefault("path"))
  result = hook(call_603802, url, valid)

proc call*(call_603803: Call_UpdateDocumentationPart_603789; body: JsonNode;
          partId: string; restapiId: string): Recallable =
  ## updateDocumentationPart
  ##   body: JObject (required)
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603804 = newJObject()
  var body_603805 = newJObject()
  if body != nil:
    body_603805 = body
  add(path_603804, "part_id", newJString(partId))
  add(path_603804, "restapi_id", newJString(restapiId))
  result = call_603803.call(path_603804, nil, nil, nil, body_603805)

var updateDocumentationPart* = Call_UpdateDocumentationPart_603789(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_603790, base: "/",
    url: url_UpdateDocumentationPart_603791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_603774 = ref object of OpenApiRestCall_602417
proc url_DeleteDocumentationPart_603776(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteDocumentationPart_603775(path: JsonNode; query: JsonNode;
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
  var valid_603777 = path.getOrDefault("part_id")
  valid_603777 = validateParameter(valid_603777, JString, required = true,
                                 default = nil)
  if valid_603777 != nil:
    section.add "part_id", valid_603777
  var valid_603778 = path.getOrDefault("restapi_id")
  valid_603778 = validateParameter(valid_603778, JString, required = true,
                                 default = nil)
  if valid_603778 != nil:
    section.add "restapi_id", valid_603778
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
  var valid_603779 = header.getOrDefault("X-Amz-Date")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Date", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Security-Token")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Security-Token", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Content-Sha256", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Algorithm")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Algorithm", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Signature")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Signature", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-SignedHeaders", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Credential")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Credential", valid_603785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603786: Call_DeleteDocumentationPart_603774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603786.validator(path, query, header, formData, body)
  let scheme = call_603786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603786.url(scheme.get, call_603786.host, call_603786.base,
                         call_603786.route, valid.getOrDefault("path"))
  result = hook(call_603786, url, valid)

proc call*(call_603787: Call_DeleteDocumentationPart_603774; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603788 = newJObject()
  add(path_603788, "part_id", newJString(partId))
  add(path_603788, "restapi_id", newJString(restapiId))
  result = call_603787.call(path_603788, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_603774(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_603775, base: "/",
    url: url_DeleteDocumentationPart_603776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_603806 = ref object of OpenApiRestCall_602417
proc url_GetDocumentationVersion_603808(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDocumentationVersion_603807(path: JsonNode; query: JsonNode;
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
  var valid_603809 = path.getOrDefault("doc_version")
  valid_603809 = validateParameter(valid_603809, JString, required = true,
                                 default = nil)
  if valid_603809 != nil:
    section.add "doc_version", valid_603809
  var valid_603810 = path.getOrDefault("restapi_id")
  valid_603810 = validateParameter(valid_603810, JString, required = true,
                                 default = nil)
  if valid_603810 != nil:
    section.add "restapi_id", valid_603810
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
  var valid_603811 = header.getOrDefault("X-Amz-Date")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Date", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-Security-Token")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Security-Token", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Content-Sha256", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Algorithm")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Algorithm", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Signature")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Signature", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-SignedHeaders", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Credential")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Credential", valid_603817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603818: Call_GetDocumentationVersion_603806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603818.validator(path, query, header, formData, body)
  let scheme = call_603818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603818.url(scheme.get, call_603818.host, call_603818.base,
                         call_603818.route, valid.getOrDefault("path"))
  result = hook(call_603818, url, valid)

proc call*(call_603819: Call_GetDocumentationVersion_603806; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603820 = newJObject()
  add(path_603820, "doc_version", newJString(docVersion))
  add(path_603820, "restapi_id", newJString(restapiId))
  result = call_603819.call(path_603820, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_603806(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_603807, base: "/",
    url: url_GetDocumentationVersion_603808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_603836 = ref object of OpenApiRestCall_602417
proc url_UpdateDocumentationVersion_603838(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateDocumentationVersion_603837(path: JsonNode; query: JsonNode;
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
  var valid_603839 = path.getOrDefault("doc_version")
  valid_603839 = validateParameter(valid_603839, JString, required = true,
                                 default = nil)
  if valid_603839 != nil:
    section.add "doc_version", valid_603839
  var valid_603840 = path.getOrDefault("restapi_id")
  valid_603840 = validateParameter(valid_603840, JString, required = true,
                                 default = nil)
  if valid_603840 != nil:
    section.add "restapi_id", valid_603840
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
  var valid_603841 = header.getOrDefault("X-Amz-Date")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Date", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Security-Token")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Security-Token", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Content-Sha256", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Algorithm")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Algorithm", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Signature")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Signature", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-SignedHeaders", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Credential")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Credential", valid_603847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603849: Call_UpdateDocumentationVersion_603836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603849.validator(path, query, header, formData, body)
  let scheme = call_603849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603849.url(scheme.get, call_603849.host, call_603849.base,
                         call_603849.route, valid.getOrDefault("path"))
  result = hook(call_603849, url, valid)

proc call*(call_603850: Call_UpdateDocumentationVersion_603836; docVersion: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  var path_603851 = newJObject()
  var body_603852 = newJObject()
  add(path_603851, "doc_version", newJString(docVersion))
  if body != nil:
    body_603852 = body
  add(path_603851, "restapi_id", newJString(restapiId))
  result = call_603850.call(path_603851, nil, nil, nil, body_603852)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_603836(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_603837, base: "/",
    url: url_UpdateDocumentationVersion_603838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_603821 = ref object of OpenApiRestCall_602417
proc url_DeleteDocumentationVersion_603823(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteDocumentationVersion_603822(path: JsonNode; query: JsonNode;
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
  var valid_603824 = path.getOrDefault("doc_version")
  valid_603824 = validateParameter(valid_603824, JString, required = true,
                                 default = nil)
  if valid_603824 != nil:
    section.add "doc_version", valid_603824
  var valid_603825 = path.getOrDefault("restapi_id")
  valid_603825 = validateParameter(valid_603825, JString, required = true,
                                 default = nil)
  if valid_603825 != nil:
    section.add "restapi_id", valid_603825
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
  var valid_603826 = header.getOrDefault("X-Amz-Date")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Date", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Security-Token")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Security-Token", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Content-Sha256", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Algorithm")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Algorithm", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Signature")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Signature", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-SignedHeaders", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Credential")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Credential", valid_603832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603833: Call_DeleteDocumentationVersion_603821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603833.validator(path, query, header, formData, body)
  let scheme = call_603833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603833.url(scheme.get, call_603833.host, call_603833.base,
                         call_603833.route, valid.getOrDefault("path"))
  result = hook(call_603833, url, valid)

proc call*(call_603834: Call_DeleteDocumentationVersion_603821; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603835 = newJObject()
  add(path_603835, "doc_version", newJString(docVersion))
  add(path_603835, "restapi_id", newJString(restapiId))
  result = call_603834.call(path_603835, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_603821(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_603822, base: "/",
    url: url_DeleteDocumentationVersion_603823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_603853 = ref object of OpenApiRestCall_602417
proc url_GetDomainName_603855(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDomainName_603854(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603856 = path.getOrDefault("domain_name")
  valid_603856 = validateParameter(valid_603856, JString, required = true,
                                 default = nil)
  if valid_603856 != nil:
    section.add "domain_name", valid_603856
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
  var valid_603857 = header.getOrDefault("X-Amz-Date")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Date", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Security-Token")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Security-Token", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Content-Sha256", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Algorithm")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Algorithm", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Signature")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Signature", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-SignedHeaders", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Credential")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Credential", valid_603863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603864: Call_GetDomainName_603853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_603864.validator(path, query, header, formData, body)
  let scheme = call_603864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603864.url(scheme.get, call_603864.host, call_603864.base,
                         call_603864.route, valid.getOrDefault("path"))
  result = hook(call_603864, url, valid)

proc call*(call_603865: Call_GetDomainName_603853; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_603866 = newJObject()
  add(path_603866, "domain_name", newJString(domainName))
  result = call_603865.call(path_603866, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_603853(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_603854,
    base: "/", url: url_GetDomainName_603855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_603881 = ref object of OpenApiRestCall_602417
proc url_UpdateDomainName_603883(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateDomainName_603882(path: JsonNode; query: JsonNode;
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
  var valid_603884 = path.getOrDefault("domain_name")
  valid_603884 = validateParameter(valid_603884, JString, required = true,
                                 default = nil)
  if valid_603884 != nil:
    section.add "domain_name", valid_603884
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
  var valid_603885 = header.getOrDefault("X-Amz-Date")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Date", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Security-Token")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Security-Token", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Content-Sha256", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Algorithm")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Algorithm", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Signature")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Signature", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-SignedHeaders", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Credential")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Credential", valid_603891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603893: Call_UpdateDomainName_603881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_603893.validator(path, query, header, formData, body)
  let scheme = call_603893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603893.url(scheme.get, call_603893.host, call_603893.base,
                         call_603893.route, valid.getOrDefault("path"))
  result = hook(call_603893, url, valid)

proc call*(call_603894: Call_UpdateDomainName_603881; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  ##   body: JObject (required)
  var path_603895 = newJObject()
  var body_603896 = newJObject()
  add(path_603895, "domain_name", newJString(domainName))
  if body != nil:
    body_603896 = body
  result = call_603894.call(path_603895, nil, nil, nil, body_603896)

var updateDomainName* = Call_UpdateDomainName_603881(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_603882,
    base: "/", url: url_UpdateDomainName_603883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_603867 = ref object of OpenApiRestCall_602417
proc url_DeleteDomainName_603869(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteDomainName_603868(path: JsonNode; query: JsonNode;
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
  var valid_603870 = path.getOrDefault("domain_name")
  valid_603870 = validateParameter(valid_603870, JString, required = true,
                                 default = nil)
  if valid_603870 != nil:
    section.add "domain_name", valid_603870
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
  var valid_603871 = header.getOrDefault("X-Amz-Date")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Date", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Security-Token")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Security-Token", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Content-Sha256", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Algorithm")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Algorithm", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Signature")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Signature", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-SignedHeaders", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Credential")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Credential", valid_603877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603878: Call_DeleteDomainName_603867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_603878.validator(path, query, header, formData, body)
  let scheme = call_603878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603878.url(scheme.get, call_603878.host, call_603878.base,
                         call_603878.route, valid.getOrDefault("path"))
  result = hook(call_603878, url, valid)

proc call*(call_603879: Call_DeleteDomainName_603867; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_603880 = newJObject()
  add(path_603880, "domain_name", newJString(domainName))
  result = call_603879.call(path_603880, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_603867(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_603868,
    base: "/", url: url_DeleteDomainName_603869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_603912 = ref object of OpenApiRestCall_602417
proc url_PutGatewayResponse_603914(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutGatewayResponse_603913(path: JsonNode; query: JsonNode;
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
  var valid_603915 = path.getOrDefault("response_type")
  valid_603915 = validateParameter(valid_603915, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603915 != nil:
    section.add "response_type", valid_603915
  var valid_603916 = path.getOrDefault("restapi_id")
  valid_603916 = validateParameter(valid_603916, JString, required = true,
                                 default = nil)
  if valid_603916 != nil:
    section.add "restapi_id", valid_603916
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
  var valid_603917 = header.getOrDefault("X-Amz-Date")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Date", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Security-Token")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Security-Token", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Content-Sha256", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Algorithm")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Algorithm", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Signature")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Signature", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-SignedHeaders", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Credential")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Credential", valid_603923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603925: Call_PutGatewayResponse_603912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_603925.validator(path, query, header, formData, body)
  let scheme = call_603925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603925.url(scheme.get, call_603925.host, call_603925.base,
                         call_603925.route, valid.getOrDefault("path"))
  result = hook(call_603925, url, valid)

proc call*(call_603926: Call_PutGatewayResponse_603912; body: JsonNode;
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
  var path_603927 = newJObject()
  var body_603928 = newJObject()
  add(path_603927, "response_type", newJString(responseType))
  if body != nil:
    body_603928 = body
  add(path_603927, "restapi_id", newJString(restapiId))
  result = call_603926.call(path_603927, nil, nil, nil, body_603928)

var putGatewayResponse* = Call_PutGatewayResponse_603912(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_603913, base: "/",
    url: url_PutGatewayResponse_603914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_603897 = ref object of OpenApiRestCall_602417
proc url_GetGatewayResponse_603899(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetGatewayResponse_603898(path: JsonNode; query: JsonNode;
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
  var valid_603900 = path.getOrDefault("response_type")
  valid_603900 = validateParameter(valid_603900, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603900 != nil:
    section.add "response_type", valid_603900
  var valid_603901 = path.getOrDefault("restapi_id")
  valid_603901 = validateParameter(valid_603901, JString, required = true,
                                 default = nil)
  if valid_603901 != nil:
    section.add "restapi_id", valid_603901
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
  var valid_603902 = header.getOrDefault("X-Amz-Date")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Date", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Security-Token")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Security-Token", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Content-Sha256", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Algorithm")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Algorithm", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Signature")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Signature", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-SignedHeaders", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Credential")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Credential", valid_603908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603909: Call_GetGatewayResponse_603897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_603909.validator(path, query, header, formData, body)
  let scheme = call_603909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603909.url(scheme.get, call_603909.host, call_603909.base,
                         call_603909.route, valid.getOrDefault("path"))
  result = hook(call_603909, url, valid)

proc call*(call_603910: Call_GetGatewayResponse_603897; restapiId: string;
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
  var path_603911 = newJObject()
  add(path_603911, "response_type", newJString(responseType))
  add(path_603911, "restapi_id", newJString(restapiId))
  result = call_603910.call(path_603911, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_603897(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_603898, base: "/",
    url: url_GetGatewayResponse_603899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_603944 = ref object of OpenApiRestCall_602417
proc url_UpdateGatewayResponse_603946(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateGatewayResponse_603945(path: JsonNode; query: JsonNode;
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
  var valid_603947 = path.getOrDefault("response_type")
  valid_603947 = validateParameter(valid_603947, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603947 != nil:
    section.add "response_type", valid_603947
  var valid_603948 = path.getOrDefault("restapi_id")
  valid_603948 = validateParameter(valid_603948, JString, required = true,
                                 default = nil)
  if valid_603948 != nil:
    section.add "restapi_id", valid_603948
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
  var valid_603949 = header.getOrDefault("X-Amz-Date")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Date", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Security-Token")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Security-Token", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Content-Sha256", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Algorithm")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Algorithm", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Signature")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Signature", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-SignedHeaders", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Credential")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Credential", valid_603955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603957: Call_UpdateGatewayResponse_603944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_603957.validator(path, query, header, formData, body)
  let scheme = call_603957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603957.url(scheme.get, call_603957.host, call_603957.base,
                         call_603957.route, valid.getOrDefault("path"))
  result = hook(call_603957, url, valid)

proc call*(call_603958: Call_UpdateGatewayResponse_603944; body: JsonNode;
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
  var path_603959 = newJObject()
  var body_603960 = newJObject()
  add(path_603959, "response_type", newJString(responseType))
  if body != nil:
    body_603960 = body
  add(path_603959, "restapi_id", newJString(restapiId))
  result = call_603958.call(path_603959, nil, nil, nil, body_603960)

var updateGatewayResponse* = Call_UpdateGatewayResponse_603944(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_603945, base: "/",
    url: url_UpdateGatewayResponse_603946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_603929 = ref object of OpenApiRestCall_602417
proc url_DeleteGatewayResponse_603931(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteGatewayResponse_603930(path: JsonNode; query: JsonNode;
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
  var valid_603932 = path.getOrDefault("response_type")
  valid_603932 = validateParameter(valid_603932, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603932 != nil:
    section.add "response_type", valid_603932
  var valid_603933 = path.getOrDefault("restapi_id")
  valid_603933 = validateParameter(valid_603933, JString, required = true,
                                 default = nil)
  if valid_603933 != nil:
    section.add "restapi_id", valid_603933
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
  var valid_603934 = header.getOrDefault("X-Amz-Date")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Date", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Security-Token")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Security-Token", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Content-Sha256", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Algorithm")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Algorithm", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Signature")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Signature", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-SignedHeaders", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Credential")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Credential", valid_603940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603941: Call_DeleteGatewayResponse_603929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_603941.validator(path, query, header, formData, body)
  let scheme = call_603941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603941.url(scheme.get, call_603941.host, call_603941.base,
                         call_603941.route, valid.getOrDefault("path"))
  result = hook(call_603941, url, valid)

proc call*(call_603942: Call_DeleteGatewayResponse_603929; restapiId: string;
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
  var path_603943 = newJObject()
  add(path_603943, "response_type", newJString(responseType))
  add(path_603943, "restapi_id", newJString(restapiId))
  result = call_603942.call(path_603943, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_603929(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_603930, base: "/",
    url: url_DeleteGatewayResponse_603931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_603977 = ref object of OpenApiRestCall_602417
proc url_PutIntegration_603979(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutIntegration_603978(path: JsonNode; query: JsonNode;
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
  var valid_603980 = path.getOrDefault("http_method")
  valid_603980 = validateParameter(valid_603980, JString, required = true,
                                 default = nil)
  if valid_603980 != nil:
    section.add "http_method", valid_603980
  var valid_603981 = path.getOrDefault("restapi_id")
  valid_603981 = validateParameter(valid_603981, JString, required = true,
                                 default = nil)
  if valid_603981 != nil:
    section.add "restapi_id", valid_603981
  var valid_603982 = path.getOrDefault("resource_id")
  valid_603982 = validateParameter(valid_603982, JString, required = true,
                                 default = nil)
  if valid_603982 != nil:
    section.add "resource_id", valid_603982
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
  var valid_603983 = header.getOrDefault("X-Amz-Date")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Date", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Security-Token")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Security-Token", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Content-Sha256", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Algorithm")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Algorithm", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Signature")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Signature", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-SignedHeaders", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Credential")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Credential", valid_603989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603991: Call_PutIntegration_603977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_603991.validator(path, query, header, formData, body)
  let scheme = call_603991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603991.url(scheme.get, call_603991.host, call_603991.base,
                         call_603991.route, valid.getOrDefault("path"))
  result = hook(call_603991, url, valid)

proc call*(call_603992: Call_PutIntegration_603977; httpMethod: string;
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
  var path_603993 = newJObject()
  var body_603994 = newJObject()
  add(path_603993, "http_method", newJString(httpMethod))
  if body != nil:
    body_603994 = body
  add(path_603993, "restapi_id", newJString(restapiId))
  add(path_603993, "resource_id", newJString(resourceId))
  result = call_603992.call(path_603993, nil, nil, nil, body_603994)

var putIntegration* = Call_PutIntegration_603977(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_603978, base: "/", url: url_PutIntegration_603979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_603961 = ref object of OpenApiRestCall_602417
proc url_GetIntegration_603963(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetIntegration_603962(path: JsonNode; query: JsonNode;
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
  var valid_603964 = path.getOrDefault("http_method")
  valid_603964 = validateParameter(valid_603964, JString, required = true,
                                 default = nil)
  if valid_603964 != nil:
    section.add "http_method", valid_603964
  var valid_603965 = path.getOrDefault("restapi_id")
  valid_603965 = validateParameter(valid_603965, JString, required = true,
                                 default = nil)
  if valid_603965 != nil:
    section.add "restapi_id", valid_603965
  var valid_603966 = path.getOrDefault("resource_id")
  valid_603966 = validateParameter(valid_603966, JString, required = true,
                                 default = nil)
  if valid_603966 != nil:
    section.add "resource_id", valid_603966
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
  var valid_603967 = header.getOrDefault("X-Amz-Date")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Date", valid_603967
  var valid_603968 = header.getOrDefault("X-Amz-Security-Token")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Security-Token", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Content-Sha256", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Algorithm")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Algorithm", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Signature")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Signature", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-SignedHeaders", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Credential")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Credential", valid_603973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603974: Call_GetIntegration_603961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_603974.validator(path, query, header, formData, body)
  let scheme = call_603974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603974.url(scheme.get, call_603974.host, call_603974.base,
                         call_603974.route, valid.getOrDefault("path"))
  result = hook(call_603974, url, valid)

proc call*(call_603975: Call_GetIntegration_603961; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  var path_603976 = newJObject()
  add(path_603976, "http_method", newJString(httpMethod))
  add(path_603976, "restapi_id", newJString(restapiId))
  add(path_603976, "resource_id", newJString(resourceId))
  result = call_603975.call(path_603976, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_603961(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_603962, base: "/", url: url_GetIntegration_603963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_604011 = ref object of OpenApiRestCall_602417
proc url_UpdateIntegration_604013(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateIntegration_604012(path: JsonNode; query: JsonNode;
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
  var valid_604014 = path.getOrDefault("http_method")
  valid_604014 = validateParameter(valid_604014, JString, required = true,
                                 default = nil)
  if valid_604014 != nil:
    section.add "http_method", valid_604014
  var valid_604015 = path.getOrDefault("restapi_id")
  valid_604015 = validateParameter(valid_604015, JString, required = true,
                                 default = nil)
  if valid_604015 != nil:
    section.add "restapi_id", valid_604015
  var valid_604016 = path.getOrDefault("resource_id")
  valid_604016 = validateParameter(valid_604016, JString, required = true,
                                 default = nil)
  if valid_604016 != nil:
    section.add "resource_id", valid_604016
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
  var valid_604017 = header.getOrDefault("X-Amz-Date")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Date", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Security-Token")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Security-Token", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Content-Sha256", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Algorithm")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Algorithm", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Signature")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Signature", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-SignedHeaders", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Credential")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Credential", valid_604023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604025: Call_UpdateIntegration_604011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_604025.validator(path, query, header, formData, body)
  let scheme = call_604025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604025.url(scheme.get, call_604025.host, call_604025.base,
                         call_604025.route, valid.getOrDefault("path"))
  result = hook(call_604025, url, valid)

proc call*(call_604026: Call_UpdateIntegration_604011; httpMethod: string;
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
  var path_604027 = newJObject()
  var body_604028 = newJObject()
  add(path_604027, "http_method", newJString(httpMethod))
  if body != nil:
    body_604028 = body
  add(path_604027, "restapi_id", newJString(restapiId))
  add(path_604027, "resource_id", newJString(resourceId))
  result = call_604026.call(path_604027, nil, nil, nil, body_604028)

var updateIntegration* = Call_UpdateIntegration_604011(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_604012, base: "/",
    url: url_UpdateIntegration_604013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_603995 = ref object of OpenApiRestCall_602417
proc url_DeleteIntegration_603997(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteIntegration_603996(path: JsonNode; query: JsonNode;
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
  var valid_603998 = path.getOrDefault("http_method")
  valid_603998 = validateParameter(valid_603998, JString, required = true,
                                 default = nil)
  if valid_603998 != nil:
    section.add "http_method", valid_603998
  var valid_603999 = path.getOrDefault("restapi_id")
  valid_603999 = validateParameter(valid_603999, JString, required = true,
                                 default = nil)
  if valid_603999 != nil:
    section.add "restapi_id", valid_603999
  var valid_604000 = path.getOrDefault("resource_id")
  valid_604000 = validateParameter(valid_604000, JString, required = true,
                                 default = nil)
  if valid_604000 != nil:
    section.add "resource_id", valid_604000
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
  var valid_604001 = header.getOrDefault("X-Amz-Date")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Date", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Security-Token")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Security-Token", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Content-Sha256", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Algorithm")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Algorithm", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Signature")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Signature", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-SignedHeaders", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Credential")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Credential", valid_604007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604008: Call_DeleteIntegration_603995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_604008.validator(path, query, header, formData, body)
  let scheme = call_604008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604008.url(scheme.get, call_604008.host, call_604008.base,
                         call_604008.route, valid.getOrDefault("path"))
  result = hook(call_604008, url, valid)

proc call*(call_604009: Call_DeleteIntegration_603995; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  var path_604010 = newJObject()
  add(path_604010, "http_method", newJString(httpMethod))
  add(path_604010, "restapi_id", newJString(restapiId))
  add(path_604010, "resource_id", newJString(resourceId))
  result = call_604009.call(path_604010, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_603995(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_603996, base: "/",
    url: url_DeleteIntegration_603997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_604046 = ref object of OpenApiRestCall_602417
proc url_PutIntegrationResponse_604048(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutIntegrationResponse_604047(path: JsonNode; query: JsonNode;
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
  var valid_604049 = path.getOrDefault("http_method")
  valid_604049 = validateParameter(valid_604049, JString, required = true,
                                 default = nil)
  if valid_604049 != nil:
    section.add "http_method", valid_604049
  var valid_604050 = path.getOrDefault("status_code")
  valid_604050 = validateParameter(valid_604050, JString, required = true,
                                 default = nil)
  if valid_604050 != nil:
    section.add "status_code", valid_604050
  var valid_604051 = path.getOrDefault("restapi_id")
  valid_604051 = validateParameter(valid_604051, JString, required = true,
                                 default = nil)
  if valid_604051 != nil:
    section.add "restapi_id", valid_604051
  var valid_604052 = path.getOrDefault("resource_id")
  valid_604052 = validateParameter(valid_604052, JString, required = true,
                                 default = nil)
  if valid_604052 != nil:
    section.add "resource_id", valid_604052
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
  var valid_604053 = header.getOrDefault("X-Amz-Date")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "X-Amz-Date", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Security-Token")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Security-Token", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Content-Sha256", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-Algorithm")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Algorithm", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Signature")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Signature", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-SignedHeaders", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Credential")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Credential", valid_604059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604061: Call_PutIntegrationResponse_604046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_604061.validator(path, query, header, formData, body)
  let scheme = call_604061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604061.url(scheme.get, call_604061.host, call_604061.base,
                         call_604061.route, valid.getOrDefault("path"))
  result = hook(call_604061, url, valid)

proc call*(call_604062: Call_PutIntegrationResponse_604046; httpMethod: string;
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
  var path_604063 = newJObject()
  var body_604064 = newJObject()
  add(path_604063, "http_method", newJString(httpMethod))
  add(path_604063, "status_code", newJString(statusCode))
  if body != nil:
    body_604064 = body
  add(path_604063, "restapi_id", newJString(restapiId))
  add(path_604063, "resource_id", newJString(resourceId))
  result = call_604062.call(path_604063, nil, nil, nil, body_604064)

var putIntegrationResponse* = Call_PutIntegrationResponse_604046(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_604047, base: "/",
    url: url_PutIntegrationResponse_604048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_604029 = ref object of OpenApiRestCall_602417
proc url_GetIntegrationResponse_604031(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetIntegrationResponse_604030(path: JsonNode; query: JsonNode;
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
  var valid_604032 = path.getOrDefault("http_method")
  valid_604032 = validateParameter(valid_604032, JString, required = true,
                                 default = nil)
  if valid_604032 != nil:
    section.add "http_method", valid_604032
  var valid_604033 = path.getOrDefault("status_code")
  valid_604033 = validateParameter(valid_604033, JString, required = true,
                                 default = nil)
  if valid_604033 != nil:
    section.add "status_code", valid_604033
  var valid_604034 = path.getOrDefault("restapi_id")
  valid_604034 = validateParameter(valid_604034, JString, required = true,
                                 default = nil)
  if valid_604034 != nil:
    section.add "restapi_id", valid_604034
  var valid_604035 = path.getOrDefault("resource_id")
  valid_604035 = validateParameter(valid_604035, JString, required = true,
                                 default = nil)
  if valid_604035 != nil:
    section.add "resource_id", valid_604035
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
  var valid_604036 = header.getOrDefault("X-Amz-Date")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Date", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Security-Token")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Security-Token", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Content-Sha256", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Algorithm")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Algorithm", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Signature")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Signature", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-SignedHeaders", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Credential")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Credential", valid_604042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604043: Call_GetIntegrationResponse_604029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_604043.validator(path, query, header, formData, body)
  let scheme = call_604043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604043.url(scheme.get, call_604043.host, call_604043.base,
                         call_604043.route, valid.getOrDefault("path"))
  result = hook(call_604043, url, valid)

proc call*(call_604044: Call_GetIntegrationResponse_604029; httpMethod: string;
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
  var path_604045 = newJObject()
  add(path_604045, "http_method", newJString(httpMethod))
  add(path_604045, "status_code", newJString(statusCode))
  add(path_604045, "restapi_id", newJString(restapiId))
  add(path_604045, "resource_id", newJString(resourceId))
  result = call_604044.call(path_604045, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_604029(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_604030, base: "/",
    url: url_GetIntegrationResponse_604031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_604082 = ref object of OpenApiRestCall_602417
proc url_UpdateIntegrationResponse_604084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateIntegrationResponse_604083(path: JsonNode; query: JsonNode;
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
  var valid_604085 = path.getOrDefault("http_method")
  valid_604085 = validateParameter(valid_604085, JString, required = true,
                                 default = nil)
  if valid_604085 != nil:
    section.add "http_method", valid_604085
  var valid_604086 = path.getOrDefault("status_code")
  valid_604086 = validateParameter(valid_604086, JString, required = true,
                                 default = nil)
  if valid_604086 != nil:
    section.add "status_code", valid_604086
  var valid_604087 = path.getOrDefault("restapi_id")
  valid_604087 = validateParameter(valid_604087, JString, required = true,
                                 default = nil)
  if valid_604087 != nil:
    section.add "restapi_id", valid_604087
  var valid_604088 = path.getOrDefault("resource_id")
  valid_604088 = validateParameter(valid_604088, JString, required = true,
                                 default = nil)
  if valid_604088 != nil:
    section.add "resource_id", valid_604088
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
  var valid_604089 = header.getOrDefault("X-Amz-Date")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Date", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-Security-Token")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Security-Token", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Content-Sha256", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Algorithm")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Algorithm", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Signature")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Signature", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-SignedHeaders", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Credential")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Credential", valid_604095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604097: Call_UpdateIntegrationResponse_604082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_604097.validator(path, query, header, formData, body)
  let scheme = call_604097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604097.url(scheme.get, call_604097.host, call_604097.base,
                         call_604097.route, valid.getOrDefault("path"))
  result = hook(call_604097, url, valid)

proc call*(call_604098: Call_UpdateIntegrationResponse_604082; httpMethod: string;
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
  var path_604099 = newJObject()
  var body_604100 = newJObject()
  add(path_604099, "http_method", newJString(httpMethod))
  add(path_604099, "status_code", newJString(statusCode))
  if body != nil:
    body_604100 = body
  add(path_604099, "restapi_id", newJString(restapiId))
  add(path_604099, "resource_id", newJString(resourceId))
  result = call_604098.call(path_604099, nil, nil, nil, body_604100)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_604082(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_604083, base: "/",
    url: url_UpdateIntegrationResponse_604084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_604065 = ref object of OpenApiRestCall_602417
proc url_DeleteIntegrationResponse_604067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteIntegrationResponse_604066(path: JsonNode; query: JsonNode;
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
  var valid_604068 = path.getOrDefault("http_method")
  valid_604068 = validateParameter(valid_604068, JString, required = true,
                                 default = nil)
  if valid_604068 != nil:
    section.add "http_method", valid_604068
  var valid_604069 = path.getOrDefault("status_code")
  valid_604069 = validateParameter(valid_604069, JString, required = true,
                                 default = nil)
  if valid_604069 != nil:
    section.add "status_code", valid_604069
  var valid_604070 = path.getOrDefault("restapi_id")
  valid_604070 = validateParameter(valid_604070, JString, required = true,
                                 default = nil)
  if valid_604070 != nil:
    section.add "restapi_id", valid_604070
  var valid_604071 = path.getOrDefault("resource_id")
  valid_604071 = validateParameter(valid_604071, JString, required = true,
                                 default = nil)
  if valid_604071 != nil:
    section.add "resource_id", valid_604071
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
  var valid_604072 = header.getOrDefault("X-Amz-Date")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Date", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Security-Token")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Security-Token", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Content-Sha256", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Algorithm")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Algorithm", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Signature")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Signature", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-SignedHeaders", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Credential")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Credential", valid_604078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604079: Call_DeleteIntegrationResponse_604065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_604079.validator(path, query, header, formData, body)
  let scheme = call_604079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604079.url(scheme.get, call_604079.host, call_604079.base,
                         call_604079.route, valid.getOrDefault("path"))
  result = hook(call_604079, url, valid)

proc call*(call_604080: Call_DeleteIntegrationResponse_604065; httpMethod: string;
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
  var path_604081 = newJObject()
  add(path_604081, "http_method", newJString(httpMethod))
  add(path_604081, "status_code", newJString(statusCode))
  add(path_604081, "restapi_id", newJString(restapiId))
  add(path_604081, "resource_id", newJString(resourceId))
  result = call_604080.call(path_604081, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_604065(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_604066, base: "/",
    url: url_DeleteIntegrationResponse_604067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_604117 = ref object of OpenApiRestCall_602417
proc url_PutMethod_604119(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutMethod_604118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604120 = path.getOrDefault("http_method")
  valid_604120 = validateParameter(valid_604120, JString, required = true,
                                 default = nil)
  if valid_604120 != nil:
    section.add "http_method", valid_604120
  var valid_604121 = path.getOrDefault("restapi_id")
  valid_604121 = validateParameter(valid_604121, JString, required = true,
                                 default = nil)
  if valid_604121 != nil:
    section.add "restapi_id", valid_604121
  var valid_604122 = path.getOrDefault("resource_id")
  valid_604122 = validateParameter(valid_604122, JString, required = true,
                                 default = nil)
  if valid_604122 != nil:
    section.add "resource_id", valid_604122
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
  var valid_604123 = header.getOrDefault("X-Amz-Date")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Date", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Security-Token")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Security-Token", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Content-Sha256", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Algorithm")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Algorithm", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Signature")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Signature", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-SignedHeaders", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Credential")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Credential", valid_604129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604131: Call_PutMethod_604117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_604131.validator(path, query, header, formData, body)
  let scheme = call_604131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604131.url(scheme.get, call_604131.host, call_604131.base,
                         call_604131.route, valid.getOrDefault("path"))
  result = hook(call_604131, url, valid)

proc call*(call_604132: Call_PutMethod_604117; httpMethod: string; body: JsonNode;
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
  var path_604133 = newJObject()
  var body_604134 = newJObject()
  add(path_604133, "http_method", newJString(httpMethod))
  if body != nil:
    body_604134 = body
  add(path_604133, "restapi_id", newJString(restapiId))
  add(path_604133, "resource_id", newJString(resourceId))
  result = call_604132.call(path_604133, nil, nil, nil, body_604134)

var putMethod* = Call_PutMethod_604117(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_604118,
                                    base: "/", url: url_PutMethod_604119,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_604135 = ref object of OpenApiRestCall_602417
proc url_TestInvokeMethod_604137(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_TestInvokeMethod_604136(path: JsonNode; query: JsonNode;
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
  var valid_604138 = path.getOrDefault("http_method")
  valid_604138 = validateParameter(valid_604138, JString, required = true,
                                 default = nil)
  if valid_604138 != nil:
    section.add "http_method", valid_604138
  var valid_604139 = path.getOrDefault("restapi_id")
  valid_604139 = validateParameter(valid_604139, JString, required = true,
                                 default = nil)
  if valid_604139 != nil:
    section.add "restapi_id", valid_604139
  var valid_604140 = path.getOrDefault("resource_id")
  valid_604140 = validateParameter(valid_604140, JString, required = true,
                                 default = nil)
  if valid_604140 != nil:
    section.add "resource_id", valid_604140
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
  var valid_604141 = header.getOrDefault("X-Amz-Date")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Date", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Security-Token")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Security-Token", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Content-Sha256", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Algorithm")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Algorithm", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Signature")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Signature", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-SignedHeaders", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Credential")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Credential", valid_604147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604149: Call_TestInvokeMethod_604135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_604149.validator(path, query, header, formData, body)
  let scheme = call_604149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604149.url(scheme.get, call_604149.host, call_604149.base,
                         call_604149.route, valid.getOrDefault("path"))
  result = hook(call_604149, url, valid)

proc call*(call_604150: Call_TestInvokeMethod_604135; httpMethod: string;
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
  var path_604151 = newJObject()
  var body_604152 = newJObject()
  add(path_604151, "http_method", newJString(httpMethod))
  if body != nil:
    body_604152 = body
  add(path_604151, "restapi_id", newJString(restapiId))
  add(path_604151, "resource_id", newJString(resourceId))
  result = call_604150.call(path_604151, nil, nil, nil, body_604152)

var testInvokeMethod* = Call_TestInvokeMethod_604135(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_604136, base: "/",
    url: url_TestInvokeMethod_604137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_604101 = ref object of OpenApiRestCall_602417
proc url_GetMethod_604103(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetMethod_604102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604104 = path.getOrDefault("http_method")
  valid_604104 = validateParameter(valid_604104, JString, required = true,
                                 default = nil)
  if valid_604104 != nil:
    section.add "http_method", valid_604104
  var valid_604105 = path.getOrDefault("restapi_id")
  valid_604105 = validateParameter(valid_604105, JString, required = true,
                                 default = nil)
  if valid_604105 != nil:
    section.add "restapi_id", valid_604105
  var valid_604106 = path.getOrDefault("resource_id")
  valid_604106 = validateParameter(valid_604106, JString, required = true,
                                 default = nil)
  if valid_604106 != nil:
    section.add "resource_id", valid_604106
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
  var valid_604107 = header.getOrDefault("X-Amz-Date")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Date", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Security-Token")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Security-Token", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Content-Sha256", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Algorithm")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Algorithm", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Signature")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Signature", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-SignedHeaders", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Credential")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Credential", valid_604113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604114: Call_GetMethod_604101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_604114.validator(path, query, header, formData, body)
  let scheme = call_604114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604114.url(scheme.get, call_604114.host, call_604114.base,
                         call_604114.route, valid.getOrDefault("path"))
  result = hook(call_604114, url, valid)

proc call*(call_604115: Call_GetMethod_604101; httpMethod: string; restapiId: string;
          resourceId: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_604116 = newJObject()
  add(path_604116, "http_method", newJString(httpMethod))
  add(path_604116, "restapi_id", newJString(restapiId))
  add(path_604116, "resource_id", newJString(resourceId))
  result = call_604115.call(path_604116, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_604101(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_604102,
                                    base: "/", url: url_GetMethod_604103,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_604169 = ref object of OpenApiRestCall_602417
proc url_UpdateMethod_604171(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateMethod_604170(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604172 = path.getOrDefault("http_method")
  valid_604172 = validateParameter(valid_604172, JString, required = true,
                                 default = nil)
  if valid_604172 != nil:
    section.add "http_method", valid_604172
  var valid_604173 = path.getOrDefault("restapi_id")
  valid_604173 = validateParameter(valid_604173, JString, required = true,
                                 default = nil)
  if valid_604173 != nil:
    section.add "restapi_id", valid_604173
  var valid_604174 = path.getOrDefault("resource_id")
  valid_604174 = validateParameter(valid_604174, JString, required = true,
                                 default = nil)
  if valid_604174 != nil:
    section.add "resource_id", valid_604174
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
  var valid_604175 = header.getOrDefault("X-Amz-Date")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Date", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-Security-Token")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Security-Token", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Content-Sha256", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Algorithm")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Algorithm", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-Signature")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Signature", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-SignedHeaders", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Credential")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Credential", valid_604181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604183: Call_UpdateMethod_604169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_604183.validator(path, query, header, formData, body)
  let scheme = call_604183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604183.url(scheme.get, call_604183.host, call_604183.base,
                         call_604183.route, valid.getOrDefault("path"))
  result = hook(call_604183, url, valid)

proc call*(call_604184: Call_UpdateMethod_604169; httpMethod: string; body: JsonNode;
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
  var path_604185 = newJObject()
  var body_604186 = newJObject()
  add(path_604185, "http_method", newJString(httpMethod))
  if body != nil:
    body_604186 = body
  add(path_604185, "restapi_id", newJString(restapiId))
  add(path_604185, "resource_id", newJString(resourceId))
  result = call_604184.call(path_604185, nil, nil, nil, body_604186)

var updateMethod* = Call_UpdateMethod_604169(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_604170, base: "/", url: url_UpdateMethod_604171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_604153 = ref object of OpenApiRestCall_602417
proc url_DeleteMethod_604155(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteMethod_604154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604156 = path.getOrDefault("http_method")
  valid_604156 = validateParameter(valid_604156, JString, required = true,
                                 default = nil)
  if valid_604156 != nil:
    section.add "http_method", valid_604156
  var valid_604157 = path.getOrDefault("restapi_id")
  valid_604157 = validateParameter(valid_604157, JString, required = true,
                                 default = nil)
  if valid_604157 != nil:
    section.add "restapi_id", valid_604157
  var valid_604158 = path.getOrDefault("resource_id")
  valid_604158 = validateParameter(valid_604158, JString, required = true,
                                 default = nil)
  if valid_604158 != nil:
    section.add "resource_id", valid_604158
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
  var valid_604159 = header.getOrDefault("X-Amz-Date")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Date", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Security-Token")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Security-Token", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Content-Sha256", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Algorithm")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Algorithm", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Signature")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Signature", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-SignedHeaders", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Credential")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Credential", valid_604165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604166: Call_DeleteMethod_604153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_604166.validator(path, query, header, formData, body)
  let scheme = call_604166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604166.url(scheme.get, call_604166.host, call_604166.base,
                         call_604166.route, valid.getOrDefault("path"))
  result = hook(call_604166, url, valid)

proc call*(call_604167: Call_DeleteMethod_604153; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_604168 = newJObject()
  add(path_604168, "http_method", newJString(httpMethod))
  add(path_604168, "restapi_id", newJString(restapiId))
  add(path_604168, "resource_id", newJString(resourceId))
  result = call_604167.call(path_604168, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_604153(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_604154, base: "/", url: url_DeleteMethod_604155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_604204 = ref object of OpenApiRestCall_602417
proc url_PutMethodResponse_604206(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutMethodResponse_604205(path: JsonNode; query: JsonNode;
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
  var valid_604207 = path.getOrDefault("http_method")
  valid_604207 = validateParameter(valid_604207, JString, required = true,
                                 default = nil)
  if valid_604207 != nil:
    section.add "http_method", valid_604207
  var valid_604208 = path.getOrDefault("status_code")
  valid_604208 = validateParameter(valid_604208, JString, required = true,
                                 default = nil)
  if valid_604208 != nil:
    section.add "status_code", valid_604208
  var valid_604209 = path.getOrDefault("restapi_id")
  valid_604209 = validateParameter(valid_604209, JString, required = true,
                                 default = nil)
  if valid_604209 != nil:
    section.add "restapi_id", valid_604209
  var valid_604210 = path.getOrDefault("resource_id")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = nil)
  if valid_604210 != nil:
    section.add "resource_id", valid_604210
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
  var valid_604211 = header.getOrDefault("X-Amz-Date")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Date", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Security-Token")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Security-Token", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Content-Sha256", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Algorithm")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Algorithm", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Signature")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Signature", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-SignedHeaders", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Credential")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Credential", valid_604217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604219: Call_PutMethodResponse_604204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_604219.validator(path, query, header, formData, body)
  let scheme = call_604219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604219.url(scheme.get, call_604219.host, call_604219.base,
                         call_604219.route, valid.getOrDefault("path"))
  result = hook(call_604219, url, valid)

proc call*(call_604220: Call_PutMethodResponse_604204; httpMethod: string;
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
  var path_604221 = newJObject()
  var body_604222 = newJObject()
  add(path_604221, "http_method", newJString(httpMethod))
  add(path_604221, "status_code", newJString(statusCode))
  if body != nil:
    body_604222 = body
  add(path_604221, "restapi_id", newJString(restapiId))
  add(path_604221, "resource_id", newJString(resourceId))
  result = call_604220.call(path_604221, nil, nil, nil, body_604222)

var putMethodResponse* = Call_PutMethodResponse_604204(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_604205, base: "/",
    url: url_PutMethodResponse_604206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_604187 = ref object of OpenApiRestCall_602417
proc url_GetMethodResponse_604189(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetMethodResponse_604188(path: JsonNode; query: JsonNode;
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
  var valid_604190 = path.getOrDefault("http_method")
  valid_604190 = validateParameter(valid_604190, JString, required = true,
                                 default = nil)
  if valid_604190 != nil:
    section.add "http_method", valid_604190
  var valid_604191 = path.getOrDefault("status_code")
  valid_604191 = validateParameter(valid_604191, JString, required = true,
                                 default = nil)
  if valid_604191 != nil:
    section.add "status_code", valid_604191
  var valid_604192 = path.getOrDefault("restapi_id")
  valid_604192 = validateParameter(valid_604192, JString, required = true,
                                 default = nil)
  if valid_604192 != nil:
    section.add "restapi_id", valid_604192
  var valid_604193 = path.getOrDefault("resource_id")
  valid_604193 = validateParameter(valid_604193, JString, required = true,
                                 default = nil)
  if valid_604193 != nil:
    section.add "resource_id", valid_604193
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
  var valid_604194 = header.getOrDefault("X-Amz-Date")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Date", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Security-Token")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Security-Token", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Content-Sha256", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Algorithm")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Algorithm", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Signature")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Signature", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-SignedHeaders", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Credential")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Credential", valid_604200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604201: Call_GetMethodResponse_604187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_604201.validator(path, query, header, formData, body)
  let scheme = call_604201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604201.url(scheme.get, call_604201.host, call_604201.base,
                         call_604201.route, valid.getOrDefault("path"))
  result = hook(call_604201, url, valid)

proc call*(call_604202: Call_GetMethodResponse_604187; httpMethod: string;
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
  var path_604203 = newJObject()
  add(path_604203, "http_method", newJString(httpMethod))
  add(path_604203, "status_code", newJString(statusCode))
  add(path_604203, "restapi_id", newJString(restapiId))
  add(path_604203, "resource_id", newJString(resourceId))
  result = call_604202.call(path_604203, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_604187(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_604188, base: "/",
    url: url_GetMethodResponse_604189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_604240 = ref object of OpenApiRestCall_602417
proc url_UpdateMethodResponse_604242(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateMethodResponse_604241(path: JsonNode; query: JsonNode;
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
  var valid_604243 = path.getOrDefault("http_method")
  valid_604243 = validateParameter(valid_604243, JString, required = true,
                                 default = nil)
  if valid_604243 != nil:
    section.add "http_method", valid_604243
  var valid_604244 = path.getOrDefault("status_code")
  valid_604244 = validateParameter(valid_604244, JString, required = true,
                                 default = nil)
  if valid_604244 != nil:
    section.add "status_code", valid_604244
  var valid_604245 = path.getOrDefault("restapi_id")
  valid_604245 = validateParameter(valid_604245, JString, required = true,
                                 default = nil)
  if valid_604245 != nil:
    section.add "restapi_id", valid_604245
  var valid_604246 = path.getOrDefault("resource_id")
  valid_604246 = validateParameter(valid_604246, JString, required = true,
                                 default = nil)
  if valid_604246 != nil:
    section.add "resource_id", valid_604246
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
  var valid_604247 = header.getOrDefault("X-Amz-Date")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Date", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Security-Token")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Security-Token", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Content-Sha256", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Algorithm")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Algorithm", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-Signature")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-Signature", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-SignedHeaders", valid_604252
  var valid_604253 = header.getOrDefault("X-Amz-Credential")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Credential", valid_604253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604255: Call_UpdateMethodResponse_604240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_604255.validator(path, query, header, formData, body)
  let scheme = call_604255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604255.url(scheme.get, call_604255.host, call_604255.base,
                         call_604255.route, valid.getOrDefault("path"))
  result = hook(call_604255, url, valid)

proc call*(call_604256: Call_UpdateMethodResponse_604240; httpMethod: string;
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
  var path_604257 = newJObject()
  var body_604258 = newJObject()
  add(path_604257, "http_method", newJString(httpMethod))
  add(path_604257, "status_code", newJString(statusCode))
  if body != nil:
    body_604258 = body
  add(path_604257, "restapi_id", newJString(restapiId))
  add(path_604257, "resource_id", newJString(resourceId))
  result = call_604256.call(path_604257, nil, nil, nil, body_604258)

var updateMethodResponse* = Call_UpdateMethodResponse_604240(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_604241, base: "/",
    url: url_UpdateMethodResponse_604242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_604223 = ref object of OpenApiRestCall_602417
proc url_DeleteMethodResponse_604225(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteMethodResponse_604224(path: JsonNode; query: JsonNode;
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
  var valid_604226 = path.getOrDefault("http_method")
  valid_604226 = validateParameter(valid_604226, JString, required = true,
                                 default = nil)
  if valid_604226 != nil:
    section.add "http_method", valid_604226
  var valid_604227 = path.getOrDefault("status_code")
  valid_604227 = validateParameter(valid_604227, JString, required = true,
                                 default = nil)
  if valid_604227 != nil:
    section.add "status_code", valid_604227
  var valid_604228 = path.getOrDefault("restapi_id")
  valid_604228 = validateParameter(valid_604228, JString, required = true,
                                 default = nil)
  if valid_604228 != nil:
    section.add "restapi_id", valid_604228
  var valid_604229 = path.getOrDefault("resource_id")
  valid_604229 = validateParameter(valid_604229, JString, required = true,
                                 default = nil)
  if valid_604229 != nil:
    section.add "resource_id", valid_604229
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
  var valid_604230 = header.getOrDefault("X-Amz-Date")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Date", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Security-Token")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Security-Token", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Content-Sha256", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Algorithm")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Algorithm", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Signature")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Signature", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-SignedHeaders", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-Credential")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-Credential", valid_604236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604237: Call_DeleteMethodResponse_604223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_604237.validator(path, query, header, formData, body)
  let scheme = call_604237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604237.url(scheme.get, call_604237.host, call_604237.base,
                         call_604237.route, valid.getOrDefault("path"))
  result = hook(call_604237, url, valid)

proc call*(call_604238: Call_DeleteMethodResponse_604223; httpMethod: string;
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
  var path_604239 = newJObject()
  add(path_604239, "http_method", newJString(httpMethod))
  add(path_604239, "status_code", newJString(statusCode))
  add(path_604239, "restapi_id", newJString(restapiId))
  add(path_604239, "resource_id", newJString(resourceId))
  result = call_604238.call(path_604239, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_604223(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_604224, base: "/",
    url: url_DeleteMethodResponse_604225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_604259 = ref object of OpenApiRestCall_602417
proc url_GetModel_604261(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetModel_604260(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604262 = path.getOrDefault("model_name")
  valid_604262 = validateParameter(valid_604262, JString, required = true,
                                 default = nil)
  if valid_604262 != nil:
    section.add "model_name", valid_604262
  var valid_604263 = path.getOrDefault("restapi_id")
  valid_604263 = validateParameter(valid_604263, JString, required = true,
                                 default = nil)
  if valid_604263 != nil:
    section.add "restapi_id", valid_604263
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_604264 = query.getOrDefault("flatten")
  valid_604264 = validateParameter(valid_604264, JBool, required = false, default = nil)
  if valid_604264 != nil:
    section.add "flatten", valid_604264
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
  var valid_604265 = header.getOrDefault("X-Amz-Date")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Date", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Security-Token")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Security-Token", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Content-Sha256", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Algorithm")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Algorithm", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Signature")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Signature", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-SignedHeaders", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Credential")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Credential", valid_604271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604272: Call_GetModel_604259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_604272.validator(path, query, header, formData, body)
  let scheme = call_604272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604272.url(scheme.get, call_604272.host, call_604272.base,
                         call_604272.route, valid.getOrDefault("path"))
  result = hook(call_604272, url, valid)

proc call*(call_604273: Call_GetModel_604259; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_604274 = newJObject()
  var query_604275 = newJObject()
  add(query_604275, "flatten", newJBool(flatten))
  add(path_604274, "model_name", newJString(modelName))
  add(path_604274, "restapi_id", newJString(restapiId))
  result = call_604273.call(path_604274, query_604275, nil, nil, nil)

var getModel* = Call_GetModel_604259(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_604260, base: "/",
                                  url: url_GetModel_604261,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_604291 = ref object of OpenApiRestCall_602417
proc url_UpdateModel_604293(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateModel_604292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604294 = path.getOrDefault("model_name")
  valid_604294 = validateParameter(valid_604294, JString, required = true,
                                 default = nil)
  if valid_604294 != nil:
    section.add "model_name", valid_604294
  var valid_604295 = path.getOrDefault("restapi_id")
  valid_604295 = validateParameter(valid_604295, JString, required = true,
                                 default = nil)
  if valid_604295 != nil:
    section.add "restapi_id", valid_604295
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
  var valid_604296 = header.getOrDefault("X-Amz-Date")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Date", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-Security-Token")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Security-Token", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Content-Sha256", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-Algorithm")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-Algorithm", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Signature")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Signature", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-SignedHeaders", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Credential")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Credential", valid_604302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604304: Call_UpdateModel_604291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_604304.validator(path, query, header, formData, body)
  let scheme = call_604304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604304.url(scheme.get, call_604304.host, call_604304.base,
                         call_604304.route, valid.getOrDefault("path"))
  result = hook(call_604304, url, valid)

proc call*(call_604305: Call_UpdateModel_604291; modelName: string; body: JsonNode;
          restapiId: string): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604306 = newJObject()
  var body_604307 = newJObject()
  add(path_604306, "model_name", newJString(modelName))
  if body != nil:
    body_604307 = body
  add(path_604306, "restapi_id", newJString(restapiId))
  result = call_604305.call(path_604306, nil, nil, nil, body_604307)

var updateModel* = Call_UpdateModel_604291(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_604292,
                                        base: "/", url: url_UpdateModel_604293,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_604276 = ref object of OpenApiRestCall_602417
proc url_DeleteModel_604278(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteModel_604277(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604279 = path.getOrDefault("model_name")
  valid_604279 = validateParameter(valid_604279, JString, required = true,
                                 default = nil)
  if valid_604279 != nil:
    section.add "model_name", valid_604279
  var valid_604280 = path.getOrDefault("restapi_id")
  valid_604280 = validateParameter(valid_604280, JString, required = true,
                                 default = nil)
  if valid_604280 != nil:
    section.add "restapi_id", valid_604280
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
  var valid_604281 = header.getOrDefault("X-Amz-Date")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Date", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Security-Token")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Security-Token", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Content-Sha256", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Algorithm")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Algorithm", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Signature")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Signature", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-SignedHeaders", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-Credential")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Credential", valid_604287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604288: Call_DeleteModel_604276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_604288.validator(path, query, header, formData, body)
  let scheme = call_604288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604288.url(scheme.get, call_604288.host, call_604288.base,
                         call_604288.route, valid.getOrDefault("path"))
  result = hook(call_604288, url, valid)

proc call*(call_604289: Call_DeleteModel_604276; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604290 = newJObject()
  add(path_604290, "model_name", newJString(modelName))
  add(path_604290, "restapi_id", newJString(restapiId))
  result = call_604289.call(path_604290, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_604276(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_604277,
                                        base: "/", url: url_DeleteModel_604278,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_604308 = ref object of OpenApiRestCall_602417
proc url_GetRequestValidator_604310(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetRequestValidator_604309(path: JsonNode; query: JsonNode;
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
  var valid_604311 = path.getOrDefault("requestvalidator_id")
  valid_604311 = validateParameter(valid_604311, JString, required = true,
                                 default = nil)
  if valid_604311 != nil:
    section.add "requestvalidator_id", valid_604311
  var valid_604312 = path.getOrDefault("restapi_id")
  valid_604312 = validateParameter(valid_604312, JString, required = true,
                                 default = nil)
  if valid_604312 != nil:
    section.add "restapi_id", valid_604312
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
  var valid_604313 = header.getOrDefault("X-Amz-Date")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Date", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-Security-Token")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Security-Token", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Content-Sha256", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Algorithm")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Algorithm", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Signature")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Signature", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-SignedHeaders", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Credential")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Credential", valid_604319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604320: Call_GetRequestValidator_604308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_604320.validator(path, query, header, formData, body)
  let scheme = call_604320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604320.url(scheme.get, call_604320.host, call_604320.base,
                         call_604320.route, valid.getOrDefault("path"))
  result = hook(call_604320, url, valid)

proc call*(call_604321: Call_GetRequestValidator_604308;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604322 = newJObject()
  add(path_604322, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_604322, "restapi_id", newJString(restapiId))
  result = call_604321.call(path_604322, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_604308(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_604309, base: "/",
    url: url_GetRequestValidator_604310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_604338 = ref object of OpenApiRestCall_602417
proc url_UpdateRequestValidator_604340(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateRequestValidator_604339(path: JsonNode; query: JsonNode;
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
  var valid_604341 = path.getOrDefault("requestvalidator_id")
  valid_604341 = validateParameter(valid_604341, JString, required = true,
                                 default = nil)
  if valid_604341 != nil:
    section.add "requestvalidator_id", valid_604341
  var valid_604342 = path.getOrDefault("restapi_id")
  valid_604342 = validateParameter(valid_604342, JString, required = true,
                                 default = nil)
  if valid_604342 != nil:
    section.add "restapi_id", valid_604342
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
  var valid_604343 = header.getOrDefault("X-Amz-Date")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Date", valid_604343
  var valid_604344 = header.getOrDefault("X-Amz-Security-Token")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-Security-Token", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Content-Sha256", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Algorithm")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Algorithm", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-Signature")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-Signature", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-SignedHeaders", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Credential")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Credential", valid_604349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604351: Call_UpdateRequestValidator_604338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_604351.validator(path, query, header, formData, body)
  let scheme = call_604351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604351.url(scheme.get, call_604351.host, call_604351.base,
                         call_604351.route, valid.getOrDefault("path"))
  result = hook(call_604351, url, valid)

proc call*(call_604352: Call_UpdateRequestValidator_604338;
          requestvalidatorId: string; body: JsonNode; restapiId: string): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604353 = newJObject()
  var body_604354 = newJObject()
  add(path_604353, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_604354 = body
  add(path_604353, "restapi_id", newJString(restapiId))
  result = call_604352.call(path_604353, nil, nil, nil, body_604354)

var updateRequestValidator* = Call_UpdateRequestValidator_604338(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_604339, base: "/",
    url: url_UpdateRequestValidator_604340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_604323 = ref object of OpenApiRestCall_602417
proc url_DeleteRequestValidator_604325(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteRequestValidator_604324(path: JsonNode; query: JsonNode;
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
  var valid_604326 = path.getOrDefault("requestvalidator_id")
  valid_604326 = validateParameter(valid_604326, JString, required = true,
                                 default = nil)
  if valid_604326 != nil:
    section.add "requestvalidator_id", valid_604326
  var valid_604327 = path.getOrDefault("restapi_id")
  valid_604327 = validateParameter(valid_604327, JString, required = true,
                                 default = nil)
  if valid_604327 != nil:
    section.add "restapi_id", valid_604327
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
  var valid_604328 = header.getOrDefault("X-Amz-Date")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Date", valid_604328
  var valid_604329 = header.getOrDefault("X-Amz-Security-Token")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-Security-Token", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Content-Sha256", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Algorithm")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Algorithm", valid_604331
  var valid_604332 = header.getOrDefault("X-Amz-Signature")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Signature", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-SignedHeaders", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Credential")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Credential", valid_604334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604335: Call_DeleteRequestValidator_604323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_604335.validator(path, query, header, formData, body)
  let scheme = call_604335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604335.url(scheme.get, call_604335.host, call_604335.base,
                         call_604335.route, valid.getOrDefault("path"))
  result = hook(call_604335, url, valid)

proc call*(call_604336: Call_DeleteRequestValidator_604323;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604337 = newJObject()
  add(path_604337, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_604337, "restapi_id", newJString(restapiId))
  result = call_604336.call(path_604337, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_604323(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_604324, base: "/",
    url: url_DeleteRequestValidator_604325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_604355 = ref object of OpenApiRestCall_602417
proc url_GetResource_604357(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetResource_604356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604358 = path.getOrDefault("restapi_id")
  valid_604358 = validateParameter(valid_604358, JString, required = true,
                                 default = nil)
  if valid_604358 != nil:
    section.add "restapi_id", valid_604358
  var valid_604359 = path.getOrDefault("resource_id")
  valid_604359 = validateParameter(valid_604359, JString, required = true,
                                 default = nil)
  if valid_604359 != nil:
    section.add "resource_id", valid_604359
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_604360 = query.getOrDefault("embed")
  valid_604360 = validateParameter(valid_604360, JArray, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "embed", valid_604360
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
  var valid_604361 = header.getOrDefault("X-Amz-Date")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Date", valid_604361
  var valid_604362 = header.getOrDefault("X-Amz-Security-Token")
  valid_604362 = validateParameter(valid_604362, JString, required = false,
                                 default = nil)
  if valid_604362 != nil:
    section.add "X-Amz-Security-Token", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-Content-Sha256", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Algorithm")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Algorithm", valid_604364
  var valid_604365 = header.getOrDefault("X-Amz-Signature")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Signature", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-SignedHeaders", valid_604366
  var valid_604367 = header.getOrDefault("X-Amz-Credential")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "X-Amz-Credential", valid_604367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604368: Call_GetResource_604355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_604368.validator(path, query, header, formData, body)
  let scheme = call_604368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604368.url(scheme.get, call_604368.host, call_604368.base,
                         call_604368.route, valid.getOrDefault("path"))
  result = hook(call_604368, url, valid)

proc call*(call_604369: Call_GetResource_604355; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_604370 = newJObject()
  var query_604371 = newJObject()
  if embed != nil:
    query_604371.add "embed", embed
  add(path_604370, "restapi_id", newJString(restapiId))
  add(path_604370, "resource_id", newJString(resourceId))
  result = call_604369.call(path_604370, query_604371, nil, nil, nil)

var getResource* = Call_GetResource_604355(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_604356,
                                        base: "/", url: url_GetResource_604357,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_604387 = ref object of OpenApiRestCall_602417
proc url_UpdateResource_604389(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateResource_604388(path: JsonNode; query: JsonNode;
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
  var valid_604390 = path.getOrDefault("restapi_id")
  valid_604390 = validateParameter(valid_604390, JString, required = true,
                                 default = nil)
  if valid_604390 != nil:
    section.add "restapi_id", valid_604390
  var valid_604391 = path.getOrDefault("resource_id")
  valid_604391 = validateParameter(valid_604391, JString, required = true,
                                 default = nil)
  if valid_604391 != nil:
    section.add "resource_id", valid_604391
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
  var valid_604392 = header.getOrDefault("X-Amz-Date")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Date", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Security-Token")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Security-Token", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Content-Sha256", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-Algorithm")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Algorithm", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-Signature")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-Signature", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-SignedHeaders", valid_604397
  var valid_604398 = header.getOrDefault("X-Amz-Credential")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "X-Amz-Credential", valid_604398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604400: Call_UpdateResource_604387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_604400.validator(path, query, header, formData, body)
  let scheme = call_604400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604400.url(scheme.get, call_604400.host, call_604400.base,
                         call_604400.route, valid.getOrDefault("path"))
  result = hook(call_604400, url, valid)

proc call*(call_604401: Call_UpdateResource_604387; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_604402 = newJObject()
  var body_604403 = newJObject()
  if body != nil:
    body_604403 = body
  add(path_604402, "restapi_id", newJString(restapiId))
  add(path_604402, "resource_id", newJString(resourceId))
  result = call_604401.call(path_604402, nil, nil, nil, body_604403)

var updateResource* = Call_UpdateResource_604387(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_604388, base: "/", url: url_UpdateResource_604389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_604372 = ref object of OpenApiRestCall_602417
proc url_DeleteResource_604374(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteResource_604373(path: JsonNode; query: JsonNode;
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
  var valid_604375 = path.getOrDefault("restapi_id")
  valid_604375 = validateParameter(valid_604375, JString, required = true,
                                 default = nil)
  if valid_604375 != nil:
    section.add "restapi_id", valid_604375
  var valid_604376 = path.getOrDefault("resource_id")
  valid_604376 = validateParameter(valid_604376, JString, required = true,
                                 default = nil)
  if valid_604376 != nil:
    section.add "resource_id", valid_604376
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
  var valid_604377 = header.getOrDefault("X-Amz-Date")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "X-Amz-Date", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-Security-Token")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-Security-Token", valid_604378
  var valid_604379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "X-Amz-Content-Sha256", valid_604379
  var valid_604380 = header.getOrDefault("X-Amz-Algorithm")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "X-Amz-Algorithm", valid_604380
  var valid_604381 = header.getOrDefault("X-Amz-Signature")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "X-Amz-Signature", valid_604381
  var valid_604382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "X-Amz-SignedHeaders", valid_604382
  var valid_604383 = header.getOrDefault("X-Amz-Credential")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "X-Amz-Credential", valid_604383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604384: Call_DeleteResource_604372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_604384.validator(path, query, header, formData, body)
  let scheme = call_604384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604384.url(scheme.get, call_604384.host, call_604384.base,
                         call_604384.route, valid.getOrDefault("path"))
  result = hook(call_604384, url, valid)

proc call*(call_604385: Call_DeleteResource_604372; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_604386 = newJObject()
  add(path_604386, "restapi_id", newJString(restapiId))
  add(path_604386, "resource_id", newJString(resourceId))
  result = call_604385.call(path_604386, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_604372(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_604373, base: "/", url: url_DeleteResource_604374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_604418 = ref object of OpenApiRestCall_602417
proc url_PutRestApi_604420(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutRestApi_604419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604421 = path.getOrDefault("restapi_id")
  valid_604421 = validateParameter(valid_604421, JString, required = true,
                                 default = nil)
  if valid_604421 != nil:
    section.add "restapi_id", valid_604421
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
  var valid_604422 = query.getOrDefault("parameters.0.value")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "parameters.0.value", valid_604422
  var valid_604423 = query.getOrDefault("parameters.2.value")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "parameters.2.value", valid_604423
  var valid_604424 = query.getOrDefault("parameters.1.key")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "parameters.1.key", valid_604424
  var valid_604425 = query.getOrDefault("mode")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = newJString("merge"))
  if valid_604425 != nil:
    section.add "mode", valid_604425
  var valid_604426 = query.getOrDefault("parameters.0.key")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "parameters.0.key", valid_604426
  var valid_604427 = query.getOrDefault("parameters.2.key")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "parameters.2.key", valid_604427
  var valid_604428 = query.getOrDefault("failonwarnings")
  valid_604428 = validateParameter(valid_604428, JBool, required = false, default = nil)
  if valid_604428 != nil:
    section.add "failonwarnings", valid_604428
  var valid_604429 = query.getOrDefault("parameters.1.value")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "parameters.1.value", valid_604429
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
  var valid_604430 = header.getOrDefault("X-Amz-Date")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Date", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-Security-Token")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Security-Token", valid_604431
  var valid_604432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Content-Sha256", valid_604432
  var valid_604433 = header.getOrDefault("X-Amz-Algorithm")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "X-Amz-Algorithm", valid_604433
  var valid_604434 = header.getOrDefault("X-Amz-Signature")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "X-Amz-Signature", valid_604434
  var valid_604435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-SignedHeaders", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-Credential")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-Credential", valid_604436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604438: Call_PutRestApi_604418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_604438.validator(path, query, header, formData, body)
  let scheme = call_604438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604438.url(scheme.get, call_604438.host, call_604438.base,
                         call_604438.route, valid.getOrDefault("path"))
  result = hook(call_604438, url, valid)

proc call*(call_604439: Call_PutRestApi_604418; body: JsonNode; restapiId: string;
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
  var path_604440 = newJObject()
  var query_604441 = newJObject()
  var body_604442 = newJObject()
  add(query_604441, "parameters.0.value", newJString(parameters0Value))
  add(query_604441, "parameters.2.value", newJString(parameters2Value))
  add(query_604441, "parameters.1.key", newJString(parameters1Key))
  add(query_604441, "mode", newJString(mode))
  add(query_604441, "parameters.0.key", newJString(parameters0Key))
  add(query_604441, "parameters.2.key", newJString(parameters2Key))
  add(query_604441, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_604442 = body
  add(query_604441, "parameters.1.value", newJString(parameters1Value))
  add(path_604440, "restapi_id", newJString(restapiId))
  result = call_604439.call(path_604440, query_604441, nil, nil, body_604442)

var putRestApi* = Call_PutRestApi_604418(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_604419,
                                      base: "/", url: url_PutRestApi_604420,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_604404 = ref object of OpenApiRestCall_602417
proc url_GetRestApi_604406(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetRestApi_604405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604407 = path.getOrDefault("restapi_id")
  valid_604407 = validateParameter(valid_604407, JString, required = true,
                                 default = nil)
  if valid_604407 != nil:
    section.add "restapi_id", valid_604407
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
  var valid_604408 = header.getOrDefault("X-Amz-Date")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Date", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Security-Token")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Security-Token", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Content-Sha256", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-Algorithm")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-Algorithm", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Signature")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Signature", valid_604412
  var valid_604413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "X-Amz-SignedHeaders", valid_604413
  var valid_604414 = header.getOrDefault("X-Amz-Credential")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "X-Amz-Credential", valid_604414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604415: Call_GetRestApi_604404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_604415.validator(path, query, header, formData, body)
  let scheme = call_604415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604415.url(scheme.get, call_604415.host, call_604415.base,
                         call_604415.route, valid.getOrDefault("path"))
  result = hook(call_604415, url, valid)

proc call*(call_604416: Call_GetRestApi_604404; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604417 = newJObject()
  add(path_604417, "restapi_id", newJString(restapiId))
  result = call_604416.call(path_604417, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_604404(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_604405,
                                      base: "/", url: url_GetRestApi_604406,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_604457 = ref object of OpenApiRestCall_602417
proc url_UpdateRestApi_604459(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateRestApi_604458(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604460 = path.getOrDefault("restapi_id")
  valid_604460 = validateParameter(valid_604460, JString, required = true,
                                 default = nil)
  if valid_604460 != nil:
    section.add "restapi_id", valid_604460
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
  var valid_604461 = header.getOrDefault("X-Amz-Date")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "X-Amz-Date", valid_604461
  var valid_604462 = header.getOrDefault("X-Amz-Security-Token")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Security-Token", valid_604462
  var valid_604463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Content-Sha256", valid_604463
  var valid_604464 = header.getOrDefault("X-Amz-Algorithm")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-Algorithm", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Signature")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Signature", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-SignedHeaders", valid_604466
  var valid_604467 = header.getOrDefault("X-Amz-Credential")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Credential", valid_604467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604469: Call_UpdateRestApi_604457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_604469.validator(path, query, header, formData, body)
  let scheme = call_604469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604469.url(scheme.get, call_604469.host, call_604469.base,
                         call_604469.route, valid.getOrDefault("path"))
  result = hook(call_604469, url, valid)

proc call*(call_604470: Call_UpdateRestApi_604457; body: JsonNode; restapiId: string): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604471 = newJObject()
  var body_604472 = newJObject()
  if body != nil:
    body_604472 = body
  add(path_604471, "restapi_id", newJString(restapiId))
  result = call_604470.call(path_604471, nil, nil, nil, body_604472)

var updateRestApi* = Call_UpdateRestApi_604457(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_604458,
    base: "/", url: url_UpdateRestApi_604459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_604443 = ref object of OpenApiRestCall_602417
proc url_DeleteRestApi_604445(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteRestApi_604444(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604446 = path.getOrDefault("restapi_id")
  valid_604446 = validateParameter(valid_604446, JString, required = true,
                                 default = nil)
  if valid_604446 != nil:
    section.add "restapi_id", valid_604446
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
  var valid_604447 = header.getOrDefault("X-Amz-Date")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Date", valid_604447
  var valid_604448 = header.getOrDefault("X-Amz-Security-Token")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "X-Amz-Security-Token", valid_604448
  var valid_604449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "X-Amz-Content-Sha256", valid_604449
  var valid_604450 = header.getOrDefault("X-Amz-Algorithm")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Algorithm", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-Signature")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-Signature", valid_604451
  var valid_604452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "X-Amz-SignedHeaders", valid_604452
  var valid_604453 = header.getOrDefault("X-Amz-Credential")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-Credential", valid_604453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604454: Call_DeleteRestApi_604443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_604454.validator(path, query, header, formData, body)
  let scheme = call_604454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604454.url(scheme.get, call_604454.host, call_604454.base,
                         call_604454.route, valid.getOrDefault("path"))
  result = hook(call_604454, url, valid)

proc call*(call_604455: Call_DeleteRestApi_604443; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604456 = newJObject()
  add(path_604456, "restapi_id", newJString(restapiId))
  result = call_604455.call(path_604456, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_604443(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_604444,
    base: "/", url: url_DeleteRestApi_604445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_604473 = ref object of OpenApiRestCall_602417
proc url_GetStage_604475(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetStage_604474(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604476 = path.getOrDefault("stage_name")
  valid_604476 = validateParameter(valid_604476, JString, required = true,
                                 default = nil)
  if valid_604476 != nil:
    section.add "stage_name", valid_604476
  var valid_604477 = path.getOrDefault("restapi_id")
  valid_604477 = validateParameter(valid_604477, JString, required = true,
                                 default = nil)
  if valid_604477 != nil:
    section.add "restapi_id", valid_604477
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
  var valid_604478 = header.getOrDefault("X-Amz-Date")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Date", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-Security-Token")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-Security-Token", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Content-Sha256", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Algorithm")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Algorithm", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Signature")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Signature", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-SignedHeaders", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Credential")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Credential", valid_604484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604485: Call_GetStage_604473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_604485.validator(path, query, header, formData, body)
  let scheme = call_604485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604485.url(scheme.get, call_604485.host, call_604485.base,
                         call_604485.route, valid.getOrDefault("path"))
  result = hook(call_604485, url, valid)

proc call*(call_604486: Call_GetStage_604473; stageName: string; restapiId: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604487 = newJObject()
  add(path_604487, "stage_name", newJString(stageName))
  add(path_604487, "restapi_id", newJString(restapiId))
  result = call_604486.call(path_604487, nil, nil, nil, nil)

var getStage* = Call_GetStage_604473(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_604474, base: "/",
                                  url: url_GetStage_604475,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_604503 = ref object of OpenApiRestCall_602417
proc url_UpdateStage_604505(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateStage_604504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604506 = path.getOrDefault("stage_name")
  valid_604506 = validateParameter(valid_604506, JString, required = true,
                                 default = nil)
  if valid_604506 != nil:
    section.add "stage_name", valid_604506
  var valid_604507 = path.getOrDefault("restapi_id")
  valid_604507 = validateParameter(valid_604507, JString, required = true,
                                 default = nil)
  if valid_604507 != nil:
    section.add "restapi_id", valid_604507
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
  var valid_604508 = header.getOrDefault("X-Amz-Date")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Date", valid_604508
  var valid_604509 = header.getOrDefault("X-Amz-Security-Token")
  valid_604509 = validateParameter(valid_604509, JString, required = false,
                                 default = nil)
  if valid_604509 != nil:
    section.add "X-Amz-Security-Token", valid_604509
  var valid_604510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-Content-Sha256", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-Algorithm")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Algorithm", valid_604511
  var valid_604512 = header.getOrDefault("X-Amz-Signature")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "X-Amz-Signature", valid_604512
  var valid_604513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-SignedHeaders", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Credential")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Credential", valid_604514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604516: Call_UpdateStage_604503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_604516.validator(path, query, header, formData, body)
  let scheme = call_604516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604516.url(scheme.get, call_604516.host, call_604516.base,
                         call_604516.route, valid.getOrDefault("path"))
  result = hook(call_604516, url, valid)

proc call*(call_604517: Call_UpdateStage_604503; body: JsonNode; stageName: string;
          restapiId: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604518 = newJObject()
  var body_604519 = newJObject()
  if body != nil:
    body_604519 = body
  add(path_604518, "stage_name", newJString(stageName))
  add(path_604518, "restapi_id", newJString(restapiId))
  result = call_604517.call(path_604518, nil, nil, nil, body_604519)

var updateStage* = Call_UpdateStage_604503(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_604504,
                                        base: "/", url: url_UpdateStage_604505,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_604488 = ref object of OpenApiRestCall_602417
proc url_DeleteStage_604490(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteStage_604489(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604491 = path.getOrDefault("stage_name")
  valid_604491 = validateParameter(valid_604491, JString, required = true,
                                 default = nil)
  if valid_604491 != nil:
    section.add "stage_name", valid_604491
  var valid_604492 = path.getOrDefault("restapi_id")
  valid_604492 = validateParameter(valid_604492, JString, required = true,
                                 default = nil)
  if valid_604492 != nil:
    section.add "restapi_id", valid_604492
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
  var valid_604493 = header.getOrDefault("X-Amz-Date")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Date", valid_604493
  var valid_604494 = header.getOrDefault("X-Amz-Security-Token")
  valid_604494 = validateParameter(valid_604494, JString, required = false,
                                 default = nil)
  if valid_604494 != nil:
    section.add "X-Amz-Security-Token", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Content-Sha256", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Algorithm")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Algorithm", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-Signature")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-Signature", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-SignedHeaders", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Credential")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Credential", valid_604499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604500: Call_DeleteStage_604488; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_604500.validator(path, query, header, formData, body)
  let scheme = call_604500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604500.url(scheme.get, call_604500.host, call_604500.base,
                         call_604500.route, valid.getOrDefault("path"))
  result = hook(call_604500, url, valid)

proc call*(call_604501: Call_DeleteStage_604488; stageName: string; restapiId: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604502 = newJObject()
  add(path_604502, "stage_name", newJString(stageName))
  add(path_604502, "restapi_id", newJString(restapiId))
  result = call_604501.call(path_604502, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_604488(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_604489,
                                        base: "/", url: url_DeleteStage_604490,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_604520 = ref object of OpenApiRestCall_602417
proc url_GetUsagePlan_604522(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUsagePlan_604521(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604523 = path.getOrDefault("usageplanId")
  valid_604523 = validateParameter(valid_604523, JString, required = true,
                                 default = nil)
  if valid_604523 != nil:
    section.add "usageplanId", valid_604523
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
  var valid_604524 = header.getOrDefault("X-Amz-Date")
  valid_604524 = validateParameter(valid_604524, JString, required = false,
                                 default = nil)
  if valid_604524 != nil:
    section.add "X-Amz-Date", valid_604524
  var valid_604525 = header.getOrDefault("X-Amz-Security-Token")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "X-Amz-Security-Token", valid_604525
  var valid_604526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Content-Sha256", valid_604526
  var valid_604527 = header.getOrDefault("X-Amz-Algorithm")
  valid_604527 = validateParameter(valid_604527, JString, required = false,
                                 default = nil)
  if valid_604527 != nil:
    section.add "X-Amz-Algorithm", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-Signature")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-Signature", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-SignedHeaders", valid_604529
  var valid_604530 = header.getOrDefault("X-Amz-Credential")
  valid_604530 = validateParameter(valid_604530, JString, required = false,
                                 default = nil)
  if valid_604530 != nil:
    section.add "X-Amz-Credential", valid_604530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604531: Call_GetUsagePlan_604520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_604531.validator(path, query, header, formData, body)
  let scheme = call_604531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604531.url(scheme.get, call_604531.host, call_604531.base,
                         call_604531.route, valid.getOrDefault("path"))
  result = hook(call_604531, url, valid)

proc call*(call_604532: Call_GetUsagePlan_604520; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_604533 = newJObject()
  add(path_604533, "usageplanId", newJString(usageplanId))
  result = call_604532.call(path_604533, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_604520(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_604521,
    base: "/", url: url_GetUsagePlan_604522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_604548 = ref object of OpenApiRestCall_602417
proc url_UpdateUsagePlan_604550(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateUsagePlan_604549(path: JsonNode; query: JsonNode;
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
  var valid_604551 = path.getOrDefault("usageplanId")
  valid_604551 = validateParameter(valid_604551, JString, required = true,
                                 default = nil)
  if valid_604551 != nil:
    section.add "usageplanId", valid_604551
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
  var valid_604552 = header.getOrDefault("X-Amz-Date")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Date", valid_604552
  var valid_604553 = header.getOrDefault("X-Amz-Security-Token")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "X-Amz-Security-Token", valid_604553
  var valid_604554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604554 = validateParameter(valid_604554, JString, required = false,
                                 default = nil)
  if valid_604554 != nil:
    section.add "X-Amz-Content-Sha256", valid_604554
  var valid_604555 = header.getOrDefault("X-Amz-Algorithm")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-Algorithm", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-Signature")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-Signature", valid_604556
  var valid_604557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "X-Amz-SignedHeaders", valid_604557
  var valid_604558 = header.getOrDefault("X-Amz-Credential")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Credential", valid_604558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604560: Call_UpdateUsagePlan_604548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_604560.validator(path, query, header, formData, body)
  let scheme = call_604560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604560.url(scheme.get, call_604560.host, call_604560.base,
                         call_604560.route, valid.getOrDefault("path"))
  result = hook(call_604560, url, valid)

proc call*(call_604561: Call_UpdateUsagePlan_604548; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_604562 = newJObject()
  var body_604563 = newJObject()
  add(path_604562, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_604563 = body
  result = call_604561.call(path_604562, nil, nil, nil, body_604563)

var updateUsagePlan* = Call_UpdateUsagePlan_604548(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_604549,
    base: "/", url: url_UpdateUsagePlan_604550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_604534 = ref object of OpenApiRestCall_602417
proc url_DeleteUsagePlan_604536(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteUsagePlan_604535(path: JsonNode; query: JsonNode;
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
  var valid_604537 = path.getOrDefault("usageplanId")
  valid_604537 = validateParameter(valid_604537, JString, required = true,
                                 default = nil)
  if valid_604537 != nil:
    section.add "usageplanId", valid_604537
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
  var valid_604538 = header.getOrDefault("X-Amz-Date")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Date", valid_604538
  var valid_604539 = header.getOrDefault("X-Amz-Security-Token")
  valid_604539 = validateParameter(valid_604539, JString, required = false,
                                 default = nil)
  if valid_604539 != nil:
    section.add "X-Amz-Security-Token", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Content-Sha256", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Algorithm")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Algorithm", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Signature")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Signature", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-SignedHeaders", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Credential")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Credential", valid_604544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604545: Call_DeleteUsagePlan_604534; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_604545.validator(path, query, header, formData, body)
  let scheme = call_604545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604545.url(scheme.get, call_604545.host, call_604545.base,
                         call_604545.route, valid.getOrDefault("path"))
  result = hook(call_604545, url, valid)

proc call*(call_604546: Call_DeleteUsagePlan_604534; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_604547 = newJObject()
  add(path_604547, "usageplanId", newJString(usageplanId))
  result = call_604546.call(path_604547, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_604534(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_604535,
    base: "/", url: url_DeleteUsagePlan_604536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_604564 = ref object of OpenApiRestCall_602417
proc url_GetUsagePlanKey_604566(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUsagePlanKey_604565(path: JsonNode; query: JsonNode;
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
  var valid_604567 = path.getOrDefault("keyId")
  valid_604567 = validateParameter(valid_604567, JString, required = true,
                                 default = nil)
  if valid_604567 != nil:
    section.add "keyId", valid_604567
  var valid_604568 = path.getOrDefault("usageplanId")
  valid_604568 = validateParameter(valid_604568, JString, required = true,
                                 default = nil)
  if valid_604568 != nil:
    section.add "usageplanId", valid_604568
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
  var valid_604569 = header.getOrDefault("X-Amz-Date")
  valid_604569 = validateParameter(valid_604569, JString, required = false,
                                 default = nil)
  if valid_604569 != nil:
    section.add "X-Amz-Date", valid_604569
  var valid_604570 = header.getOrDefault("X-Amz-Security-Token")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "X-Amz-Security-Token", valid_604570
  var valid_604571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604571 = validateParameter(valid_604571, JString, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "X-Amz-Content-Sha256", valid_604571
  var valid_604572 = header.getOrDefault("X-Amz-Algorithm")
  valid_604572 = validateParameter(valid_604572, JString, required = false,
                                 default = nil)
  if valid_604572 != nil:
    section.add "X-Amz-Algorithm", valid_604572
  var valid_604573 = header.getOrDefault("X-Amz-Signature")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Signature", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-SignedHeaders", valid_604574
  var valid_604575 = header.getOrDefault("X-Amz-Credential")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Credential", valid_604575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604576: Call_GetUsagePlanKey_604564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_604576.validator(path, query, header, formData, body)
  let scheme = call_604576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604576.url(scheme.get, call_604576.host, call_604576.base,
                         call_604576.route, valid.getOrDefault("path"))
  result = hook(call_604576, url, valid)

proc call*(call_604577: Call_GetUsagePlanKey_604564; keyId: string;
          usageplanId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_604578 = newJObject()
  add(path_604578, "keyId", newJString(keyId))
  add(path_604578, "usageplanId", newJString(usageplanId))
  result = call_604577.call(path_604578, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_604564(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_604565, base: "/", url: url_GetUsagePlanKey_604566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_604579 = ref object of OpenApiRestCall_602417
proc url_DeleteUsagePlanKey_604581(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteUsagePlanKey_604580(path: JsonNode; query: JsonNode;
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
  var valid_604582 = path.getOrDefault("keyId")
  valid_604582 = validateParameter(valid_604582, JString, required = true,
                                 default = nil)
  if valid_604582 != nil:
    section.add "keyId", valid_604582
  var valid_604583 = path.getOrDefault("usageplanId")
  valid_604583 = validateParameter(valid_604583, JString, required = true,
                                 default = nil)
  if valid_604583 != nil:
    section.add "usageplanId", valid_604583
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
  var valid_604584 = header.getOrDefault("X-Amz-Date")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-Date", valid_604584
  var valid_604585 = header.getOrDefault("X-Amz-Security-Token")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Security-Token", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Content-Sha256", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Algorithm")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Algorithm", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-Signature")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Signature", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-SignedHeaders", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Credential")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Credential", valid_604590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604591: Call_DeleteUsagePlanKey_604579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_604591.validator(path, query, header, formData, body)
  let scheme = call_604591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604591.url(scheme.get, call_604591.host, call_604591.base,
                         call_604591.route, valid.getOrDefault("path"))
  result = hook(call_604591, url, valid)

proc call*(call_604592: Call_DeleteUsagePlanKey_604579; keyId: string;
          usageplanId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  var path_604593 = newJObject()
  add(path_604593, "keyId", newJString(keyId))
  add(path_604593, "usageplanId", newJString(usageplanId))
  result = call_604592.call(path_604593, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_604579(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_604580, base: "/",
    url: url_DeleteUsagePlanKey_604581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_604594 = ref object of OpenApiRestCall_602417
proc url_GetVpcLink_604596(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetVpcLink_604595(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604597 = path.getOrDefault("vpclink_id")
  valid_604597 = validateParameter(valid_604597, JString, required = true,
                                 default = nil)
  if valid_604597 != nil:
    section.add "vpclink_id", valid_604597
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
  var valid_604598 = header.getOrDefault("X-Amz-Date")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "X-Amz-Date", valid_604598
  var valid_604599 = header.getOrDefault("X-Amz-Security-Token")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "X-Amz-Security-Token", valid_604599
  var valid_604600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Content-Sha256", valid_604600
  var valid_604601 = header.getOrDefault("X-Amz-Algorithm")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-Algorithm", valid_604601
  var valid_604602 = header.getOrDefault("X-Amz-Signature")
  valid_604602 = validateParameter(valid_604602, JString, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "X-Amz-Signature", valid_604602
  var valid_604603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-SignedHeaders", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-Credential")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Credential", valid_604604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604605: Call_GetVpcLink_604594; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_604605.validator(path, query, header, formData, body)
  let scheme = call_604605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604605.url(scheme.get, call_604605.host, call_604605.base,
                         call_604605.route, valid.getOrDefault("path"))
  result = hook(call_604605, url, valid)

proc call*(call_604606: Call_GetVpcLink_604594; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_604607 = newJObject()
  add(path_604607, "vpclink_id", newJString(vpclinkId))
  result = call_604606.call(path_604607, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_604594(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_604595,
                                      base: "/", url: url_GetVpcLink_604596,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_604622 = ref object of OpenApiRestCall_602417
proc url_UpdateVpcLink_604624(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateVpcLink_604623(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604625 = path.getOrDefault("vpclink_id")
  valid_604625 = validateParameter(valid_604625, JString, required = true,
                                 default = nil)
  if valid_604625 != nil:
    section.add "vpclink_id", valid_604625
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
  var valid_604626 = header.getOrDefault("X-Amz-Date")
  valid_604626 = validateParameter(valid_604626, JString, required = false,
                                 default = nil)
  if valid_604626 != nil:
    section.add "X-Amz-Date", valid_604626
  var valid_604627 = header.getOrDefault("X-Amz-Security-Token")
  valid_604627 = validateParameter(valid_604627, JString, required = false,
                                 default = nil)
  if valid_604627 != nil:
    section.add "X-Amz-Security-Token", valid_604627
  var valid_604628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604628 = validateParameter(valid_604628, JString, required = false,
                                 default = nil)
  if valid_604628 != nil:
    section.add "X-Amz-Content-Sha256", valid_604628
  var valid_604629 = header.getOrDefault("X-Amz-Algorithm")
  valid_604629 = validateParameter(valid_604629, JString, required = false,
                                 default = nil)
  if valid_604629 != nil:
    section.add "X-Amz-Algorithm", valid_604629
  var valid_604630 = header.getOrDefault("X-Amz-Signature")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "X-Amz-Signature", valid_604630
  var valid_604631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-SignedHeaders", valid_604631
  var valid_604632 = header.getOrDefault("X-Amz-Credential")
  valid_604632 = validateParameter(valid_604632, JString, required = false,
                                 default = nil)
  if valid_604632 != nil:
    section.add "X-Amz-Credential", valid_604632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604634: Call_UpdateVpcLink_604622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_604634.validator(path, query, header, formData, body)
  let scheme = call_604634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604634.url(scheme.get, call_604634.host, call_604634.base,
                         call_604634.route, valid.getOrDefault("path"))
  result = hook(call_604634, url, valid)

proc call*(call_604635: Call_UpdateVpcLink_604622; body: JsonNode; vpclinkId: string): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   body: JObject (required)
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_604636 = newJObject()
  var body_604637 = newJObject()
  if body != nil:
    body_604637 = body
  add(path_604636, "vpclink_id", newJString(vpclinkId))
  result = call_604635.call(path_604636, nil, nil, nil, body_604637)

var updateVpcLink* = Call_UpdateVpcLink_604622(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_604623,
    base: "/", url: url_UpdateVpcLink_604624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_604608 = ref object of OpenApiRestCall_602417
proc url_DeleteVpcLink_604610(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVpcLink_604609(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604611 = path.getOrDefault("vpclink_id")
  valid_604611 = validateParameter(valid_604611, JString, required = true,
                                 default = nil)
  if valid_604611 != nil:
    section.add "vpclink_id", valid_604611
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
  var valid_604612 = header.getOrDefault("X-Amz-Date")
  valid_604612 = validateParameter(valid_604612, JString, required = false,
                                 default = nil)
  if valid_604612 != nil:
    section.add "X-Amz-Date", valid_604612
  var valid_604613 = header.getOrDefault("X-Amz-Security-Token")
  valid_604613 = validateParameter(valid_604613, JString, required = false,
                                 default = nil)
  if valid_604613 != nil:
    section.add "X-Amz-Security-Token", valid_604613
  var valid_604614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "X-Amz-Content-Sha256", valid_604614
  var valid_604615 = header.getOrDefault("X-Amz-Algorithm")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "X-Amz-Algorithm", valid_604615
  var valid_604616 = header.getOrDefault("X-Amz-Signature")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "X-Amz-Signature", valid_604616
  var valid_604617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604617 = validateParameter(valid_604617, JString, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "X-Amz-SignedHeaders", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Credential")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Credential", valid_604618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604619: Call_DeleteVpcLink_604608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_604619.validator(path, query, header, formData, body)
  let scheme = call_604619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604619.url(scheme.get, call_604619.host, call_604619.base,
                         call_604619.route, valid.getOrDefault("path"))
  result = hook(call_604619, url, valid)

proc call*(call_604620: Call_DeleteVpcLink_604608; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_604621 = newJObject()
  add(path_604621, "vpclink_id", newJString(vpclinkId))
  result = call_604620.call(path_604621, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_604608(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_604609,
    base: "/", url: url_DeleteVpcLink_604610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_604638 = ref object of OpenApiRestCall_602417
proc url_FlushStageAuthorizersCache_604640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_FlushStageAuthorizersCache_604639(path: JsonNode; query: JsonNode;
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
  var valid_604641 = path.getOrDefault("stage_name")
  valid_604641 = validateParameter(valid_604641, JString, required = true,
                                 default = nil)
  if valid_604641 != nil:
    section.add "stage_name", valid_604641
  var valid_604642 = path.getOrDefault("restapi_id")
  valid_604642 = validateParameter(valid_604642, JString, required = true,
                                 default = nil)
  if valid_604642 != nil:
    section.add "restapi_id", valid_604642
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
  var valid_604643 = header.getOrDefault("X-Amz-Date")
  valid_604643 = validateParameter(valid_604643, JString, required = false,
                                 default = nil)
  if valid_604643 != nil:
    section.add "X-Amz-Date", valid_604643
  var valid_604644 = header.getOrDefault("X-Amz-Security-Token")
  valid_604644 = validateParameter(valid_604644, JString, required = false,
                                 default = nil)
  if valid_604644 != nil:
    section.add "X-Amz-Security-Token", valid_604644
  var valid_604645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604645 = validateParameter(valid_604645, JString, required = false,
                                 default = nil)
  if valid_604645 != nil:
    section.add "X-Amz-Content-Sha256", valid_604645
  var valid_604646 = header.getOrDefault("X-Amz-Algorithm")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "X-Amz-Algorithm", valid_604646
  var valid_604647 = header.getOrDefault("X-Amz-Signature")
  valid_604647 = validateParameter(valid_604647, JString, required = false,
                                 default = nil)
  if valid_604647 != nil:
    section.add "X-Amz-Signature", valid_604647
  var valid_604648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-SignedHeaders", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-Credential")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-Credential", valid_604649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604650: Call_FlushStageAuthorizersCache_604638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_604650.validator(path, query, header, formData, body)
  let scheme = call_604650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604650.url(scheme.get, call_604650.host, call_604650.base,
                         call_604650.route, valid.getOrDefault("path"))
  result = hook(call_604650, url, valid)

proc call*(call_604651: Call_FlushStageAuthorizersCache_604638; stageName: string;
          restapiId: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  var path_604652 = newJObject()
  add(path_604652, "stage_name", newJString(stageName))
  add(path_604652, "restapi_id", newJString(restapiId))
  result = call_604651.call(path_604652, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_604638(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_604639, base: "/",
    url: url_FlushStageAuthorizersCache_604640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_604653 = ref object of OpenApiRestCall_602417
proc url_FlushStageCache_604655(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_FlushStageCache_604654(path: JsonNode; query: JsonNode;
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
  var valid_604656 = path.getOrDefault("stage_name")
  valid_604656 = validateParameter(valid_604656, JString, required = true,
                                 default = nil)
  if valid_604656 != nil:
    section.add "stage_name", valid_604656
  var valid_604657 = path.getOrDefault("restapi_id")
  valid_604657 = validateParameter(valid_604657, JString, required = true,
                                 default = nil)
  if valid_604657 != nil:
    section.add "restapi_id", valid_604657
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
  var valid_604658 = header.getOrDefault("X-Amz-Date")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "X-Amz-Date", valid_604658
  var valid_604659 = header.getOrDefault("X-Amz-Security-Token")
  valid_604659 = validateParameter(valid_604659, JString, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "X-Amz-Security-Token", valid_604659
  var valid_604660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-Content-Sha256", valid_604660
  var valid_604661 = header.getOrDefault("X-Amz-Algorithm")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "X-Amz-Algorithm", valid_604661
  var valid_604662 = header.getOrDefault("X-Amz-Signature")
  valid_604662 = validateParameter(valid_604662, JString, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "X-Amz-Signature", valid_604662
  var valid_604663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-SignedHeaders", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-Credential")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-Credential", valid_604664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604665: Call_FlushStageCache_604653; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_604665.validator(path, query, header, formData, body)
  let scheme = call_604665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604665.url(scheme.get, call_604665.host, call_604665.base,
                         call_604665.route, valid.getOrDefault("path"))
  result = hook(call_604665, url, valid)

proc call*(call_604666: Call_FlushStageCache_604653; stageName: string;
          restapiId: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604667 = newJObject()
  add(path_604667, "stage_name", newJString(stageName))
  add(path_604667, "restapi_id", newJString(restapiId))
  result = call_604666.call(path_604667, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_604653(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_604654, base: "/", url: url_FlushStageCache_604655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_604683 = ref object of OpenApiRestCall_602417
proc url_GenerateClientCertificate_604685(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateClientCertificate_604684(path: JsonNode; query: JsonNode;
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
  var valid_604686 = header.getOrDefault("X-Amz-Date")
  valid_604686 = validateParameter(valid_604686, JString, required = false,
                                 default = nil)
  if valid_604686 != nil:
    section.add "X-Amz-Date", valid_604686
  var valid_604687 = header.getOrDefault("X-Amz-Security-Token")
  valid_604687 = validateParameter(valid_604687, JString, required = false,
                                 default = nil)
  if valid_604687 != nil:
    section.add "X-Amz-Security-Token", valid_604687
  var valid_604688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604688 = validateParameter(valid_604688, JString, required = false,
                                 default = nil)
  if valid_604688 != nil:
    section.add "X-Amz-Content-Sha256", valid_604688
  var valid_604689 = header.getOrDefault("X-Amz-Algorithm")
  valid_604689 = validateParameter(valid_604689, JString, required = false,
                                 default = nil)
  if valid_604689 != nil:
    section.add "X-Amz-Algorithm", valid_604689
  var valid_604690 = header.getOrDefault("X-Amz-Signature")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-Signature", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-SignedHeaders", valid_604691
  var valid_604692 = header.getOrDefault("X-Amz-Credential")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "X-Amz-Credential", valid_604692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604694: Call_GenerateClientCertificate_604683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_604694.validator(path, query, header, formData, body)
  let scheme = call_604694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604694.url(scheme.get, call_604694.host, call_604694.base,
                         call_604694.route, valid.getOrDefault("path"))
  result = hook(call_604694, url, valid)

proc call*(call_604695: Call_GenerateClientCertificate_604683; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_604696 = newJObject()
  if body != nil:
    body_604696 = body
  result = call_604695.call(nil, nil, nil, nil, body_604696)

var generateClientCertificate* = Call_GenerateClientCertificate_604683(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_604684, base: "/",
    url: url_GenerateClientCertificate_604685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_604668 = ref object of OpenApiRestCall_602417
proc url_GetClientCertificates_604670(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetClientCertificates_604669(path: JsonNode; query: JsonNode;
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
  var valid_604671 = query.getOrDefault("position")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "position", valid_604671
  var valid_604672 = query.getOrDefault("limit")
  valid_604672 = validateParameter(valid_604672, JInt, required = false, default = nil)
  if valid_604672 != nil:
    section.add "limit", valid_604672
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
  var valid_604673 = header.getOrDefault("X-Amz-Date")
  valid_604673 = validateParameter(valid_604673, JString, required = false,
                                 default = nil)
  if valid_604673 != nil:
    section.add "X-Amz-Date", valid_604673
  var valid_604674 = header.getOrDefault("X-Amz-Security-Token")
  valid_604674 = validateParameter(valid_604674, JString, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "X-Amz-Security-Token", valid_604674
  var valid_604675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Content-Sha256", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-Algorithm")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Algorithm", valid_604676
  var valid_604677 = header.getOrDefault("X-Amz-Signature")
  valid_604677 = validateParameter(valid_604677, JString, required = false,
                                 default = nil)
  if valid_604677 != nil:
    section.add "X-Amz-Signature", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-SignedHeaders", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Credential")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Credential", valid_604679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604680: Call_GetClientCertificates_604668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_604680.validator(path, query, header, formData, body)
  let scheme = call_604680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604680.url(scheme.get, call_604680.host, call_604680.base,
                         call_604680.route, valid.getOrDefault("path"))
  result = hook(call_604680, url, valid)

proc call*(call_604681: Call_GetClientCertificates_604668; position: string = "";
          limit: int = 0): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_604682 = newJObject()
  add(query_604682, "position", newJString(position))
  add(query_604682, "limit", newJInt(limit))
  result = call_604681.call(nil, query_604682, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_604668(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_604669, base: "/",
    url: url_GetClientCertificates_604670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_604697 = ref object of OpenApiRestCall_602417
proc url_GetAccount_604699(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAccount_604698(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604700 = header.getOrDefault("X-Amz-Date")
  valid_604700 = validateParameter(valid_604700, JString, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "X-Amz-Date", valid_604700
  var valid_604701 = header.getOrDefault("X-Amz-Security-Token")
  valid_604701 = validateParameter(valid_604701, JString, required = false,
                                 default = nil)
  if valid_604701 != nil:
    section.add "X-Amz-Security-Token", valid_604701
  var valid_604702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604702 = validateParameter(valid_604702, JString, required = false,
                                 default = nil)
  if valid_604702 != nil:
    section.add "X-Amz-Content-Sha256", valid_604702
  var valid_604703 = header.getOrDefault("X-Amz-Algorithm")
  valid_604703 = validateParameter(valid_604703, JString, required = false,
                                 default = nil)
  if valid_604703 != nil:
    section.add "X-Amz-Algorithm", valid_604703
  var valid_604704 = header.getOrDefault("X-Amz-Signature")
  valid_604704 = validateParameter(valid_604704, JString, required = false,
                                 default = nil)
  if valid_604704 != nil:
    section.add "X-Amz-Signature", valid_604704
  var valid_604705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "X-Amz-SignedHeaders", valid_604705
  var valid_604706 = header.getOrDefault("X-Amz-Credential")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Credential", valid_604706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604707: Call_GetAccount_604697; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_604707.validator(path, query, header, formData, body)
  let scheme = call_604707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604707.url(scheme.get, call_604707.host, call_604707.base,
                         call_604707.route, valid.getOrDefault("path"))
  result = hook(call_604707, url, valid)

proc call*(call_604708: Call_GetAccount_604697): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_604708.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_604697(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_604698,
                                      base: "/", url: url_GetAccount_604699,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_604709 = ref object of OpenApiRestCall_602417
proc url_UpdateAccount_604711(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAccount_604710(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604712 = header.getOrDefault("X-Amz-Date")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Date", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-Security-Token")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-Security-Token", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-Content-Sha256", valid_604714
  var valid_604715 = header.getOrDefault("X-Amz-Algorithm")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-Algorithm", valid_604715
  var valid_604716 = header.getOrDefault("X-Amz-Signature")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "X-Amz-Signature", valid_604716
  var valid_604717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604717 = validateParameter(valid_604717, JString, required = false,
                                 default = nil)
  if valid_604717 != nil:
    section.add "X-Amz-SignedHeaders", valid_604717
  var valid_604718 = header.getOrDefault("X-Amz-Credential")
  valid_604718 = validateParameter(valid_604718, JString, required = false,
                                 default = nil)
  if valid_604718 != nil:
    section.add "X-Amz-Credential", valid_604718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604720: Call_UpdateAccount_604709; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_604720.validator(path, query, header, formData, body)
  let scheme = call_604720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604720.url(scheme.get, call_604720.host, call_604720.base,
                         call_604720.route, valid.getOrDefault("path"))
  result = hook(call_604720, url, valid)

proc call*(call_604721: Call_UpdateAccount_604709; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_604722 = newJObject()
  if body != nil:
    body_604722 = body
  result = call_604721.call(nil, nil, nil, nil, body_604722)

var updateAccount* = Call_UpdateAccount_604709(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_604710, base: "/", url: url_UpdateAccount_604711,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_604723 = ref object of OpenApiRestCall_602417
proc url_GetExport_604725(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetExport_604724(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604726 = path.getOrDefault("export_type")
  valid_604726 = validateParameter(valid_604726, JString, required = true,
                                 default = nil)
  if valid_604726 != nil:
    section.add "export_type", valid_604726
  var valid_604727 = path.getOrDefault("stage_name")
  valid_604727 = validateParameter(valid_604727, JString, required = true,
                                 default = nil)
  if valid_604727 != nil:
    section.add "stage_name", valid_604727
  var valid_604728 = path.getOrDefault("restapi_id")
  valid_604728 = validateParameter(valid_604728, JString, required = true,
                                 default = nil)
  if valid_604728 != nil:
    section.add "restapi_id", valid_604728
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_604729 = query.getOrDefault("parameters.0.value")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "parameters.0.value", valid_604729
  var valid_604730 = query.getOrDefault("parameters.2.value")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "parameters.2.value", valid_604730
  var valid_604731 = query.getOrDefault("parameters.1.key")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "parameters.1.key", valid_604731
  var valid_604732 = query.getOrDefault("parameters.0.key")
  valid_604732 = validateParameter(valid_604732, JString, required = false,
                                 default = nil)
  if valid_604732 != nil:
    section.add "parameters.0.key", valid_604732
  var valid_604733 = query.getOrDefault("parameters.2.key")
  valid_604733 = validateParameter(valid_604733, JString, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "parameters.2.key", valid_604733
  var valid_604734 = query.getOrDefault("parameters.1.value")
  valid_604734 = validateParameter(valid_604734, JString, required = false,
                                 default = nil)
  if valid_604734 != nil:
    section.add "parameters.1.value", valid_604734
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
  var valid_604735 = header.getOrDefault("X-Amz-Date")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-Date", valid_604735
  var valid_604736 = header.getOrDefault("X-Amz-Security-Token")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "X-Amz-Security-Token", valid_604736
  var valid_604737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604737 = validateParameter(valid_604737, JString, required = false,
                                 default = nil)
  if valid_604737 != nil:
    section.add "X-Amz-Content-Sha256", valid_604737
  var valid_604738 = header.getOrDefault("X-Amz-Algorithm")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-Algorithm", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-Signature")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-Signature", valid_604739
  var valid_604740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "X-Amz-SignedHeaders", valid_604740
  var valid_604741 = header.getOrDefault("Accept")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "Accept", valid_604741
  var valid_604742 = header.getOrDefault("X-Amz-Credential")
  valid_604742 = validateParameter(valid_604742, JString, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "X-Amz-Credential", valid_604742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604743: Call_GetExport_604723; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_604743.validator(path, query, header, formData, body)
  let scheme = call_604743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604743.url(scheme.get, call_604743.host, call_604743.base,
                         call_604743.route, valid.getOrDefault("path"))
  result = hook(call_604743, url, valid)

proc call*(call_604744: Call_GetExport_604723; exportType: string; stageName: string;
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
  var path_604745 = newJObject()
  var query_604746 = newJObject()
  add(query_604746, "parameters.0.value", newJString(parameters0Value))
  add(query_604746, "parameters.2.value", newJString(parameters2Value))
  add(query_604746, "parameters.1.key", newJString(parameters1Key))
  add(query_604746, "parameters.0.key", newJString(parameters0Key))
  add(path_604745, "export_type", newJString(exportType))
  add(query_604746, "parameters.2.key", newJString(parameters2Key))
  add(path_604745, "stage_name", newJString(stageName))
  add(query_604746, "parameters.1.value", newJString(parameters1Value))
  add(path_604745, "restapi_id", newJString(restapiId))
  result = call_604744.call(path_604745, query_604746, nil, nil, nil)

var getExport* = Call_GetExport_604723(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_604724,
                                    base: "/", url: url_GetExport_604725,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_604747 = ref object of OpenApiRestCall_602417
proc url_GetGatewayResponses_604749(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/gatewayresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetGatewayResponses_604748(path: JsonNode; query: JsonNode;
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
  var valid_604750 = path.getOrDefault("restapi_id")
  valid_604750 = validateParameter(valid_604750, JString, required = true,
                                 default = nil)
  if valid_604750 != nil:
    section.add "restapi_id", valid_604750
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  section = newJObject()
  var valid_604751 = query.getOrDefault("position")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "position", valid_604751
  var valid_604752 = query.getOrDefault("limit")
  valid_604752 = validateParameter(valid_604752, JInt, required = false, default = nil)
  if valid_604752 != nil:
    section.add "limit", valid_604752
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
  var valid_604753 = header.getOrDefault("X-Amz-Date")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-Date", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-Security-Token")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-Security-Token", valid_604754
  var valid_604755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604755 = validateParameter(valid_604755, JString, required = false,
                                 default = nil)
  if valid_604755 != nil:
    section.add "X-Amz-Content-Sha256", valid_604755
  var valid_604756 = header.getOrDefault("X-Amz-Algorithm")
  valid_604756 = validateParameter(valid_604756, JString, required = false,
                                 default = nil)
  if valid_604756 != nil:
    section.add "X-Amz-Algorithm", valid_604756
  var valid_604757 = header.getOrDefault("X-Amz-Signature")
  valid_604757 = validateParameter(valid_604757, JString, required = false,
                                 default = nil)
  if valid_604757 != nil:
    section.add "X-Amz-Signature", valid_604757
  var valid_604758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604758 = validateParameter(valid_604758, JString, required = false,
                                 default = nil)
  if valid_604758 != nil:
    section.add "X-Amz-SignedHeaders", valid_604758
  var valid_604759 = header.getOrDefault("X-Amz-Credential")
  valid_604759 = validateParameter(valid_604759, JString, required = false,
                                 default = nil)
  if valid_604759 != nil:
    section.add "X-Amz-Credential", valid_604759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604760: Call_GetGatewayResponses_604747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_604760.validator(path, query, header, formData, body)
  let scheme = call_604760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604760.url(scheme.get, call_604760.host, call_604760.base,
                         call_604760.route, valid.getOrDefault("path"))
  result = hook(call_604760, url, valid)

proc call*(call_604761: Call_GetGatewayResponses_604747; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604762 = newJObject()
  var query_604763 = newJObject()
  add(query_604763, "position", newJString(position))
  add(query_604763, "limit", newJInt(limit))
  add(path_604762, "restapi_id", newJString(restapiId))
  result = call_604761.call(path_604762, query_604763, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_604747(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_604748, base: "/",
    url: url_GetGatewayResponses_604749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_604764 = ref object of OpenApiRestCall_602417
proc url_GetModelTemplate_604766(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetModelTemplate_604765(path: JsonNode; query: JsonNode;
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
  var valid_604767 = path.getOrDefault("model_name")
  valid_604767 = validateParameter(valid_604767, JString, required = true,
                                 default = nil)
  if valid_604767 != nil:
    section.add "model_name", valid_604767
  var valid_604768 = path.getOrDefault("restapi_id")
  valid_604768 = validateParameter(valid_604768, JString, required = true,
                                 default = nil)
  if valid_604768 != nil:
    section.add "restapi_id", valid_604768
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
  var valid_604769 = header.getOrDefault("X-Amz-Date")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Date", valid_604769
  var valid_604770 = header.getOrDefault("X-Amz-Security-Token")
  valid_604770 = validateParameter(valid_604770, JString, required = false,
                                 default = nil)
  if valid_604770 != nil:
    section.add "X-Amz-Security-Token", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-Content-Sha256", valid_604771
  var valid_604772 = header.getOrDefault("X-Amz-Algorithm")
  valid_604772 = validateParameter(valid_604772, JString, required = false,
                                 default = nil)
  if valid_604772 != nil:
    section.add "X-Amz-Algorithm", valid_604772
  var valid_604773 = header.getOrDefault("X-Amz-Signature")
  valid_604773 = validateParameter(valid_604773, JString, required = false,
                                 default = nil)
  if valid_604773 != nil:
    section.add "X-Amz-Signature", valid_604773
  var valid_604774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604774 = validateParameter(valid_604774, JString, required = false,
                                 default = nil)
  if valid_604774 != nil:
    section.add "X-Amz-SignedHeaders", valid_604774
  var valid_604775 = header.getOrDefault("X-Amz-Credential")
  valid_604775 = validateParameter(valid_604775, JString, required = false,
                                 default = nil)
  if valid_604775 != nil:
    section.add "X-Amz-Credential", valid_604775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604776: Call_GetModelTemplate_604764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_604776.validator(path, query, header, formData, body)
  let scheme = call_604776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604776.url(scheme.get, call_604776.host, call_604776.base,
                         call_604776.route, valid.getOrDefault("path"))
  result = hook(call_604776, url, valid)

proc call*(call_604777: Call_GetModelTemplate_604764; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604778 = newJObject()
  add(path_604778, "model_name", newJString(modelName))
  add(path_604778, "restapi_id", newJString(restapiId))
  result = call_604777.call(path_604778, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_604764(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_604765, base: "/",
    url: url_GetModelTemplate_604766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_604779 = ref object of OpenApiRestCall_602417
proc url_GetResources_604781(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id"),
               (kind: ConstantSegment, value: "/resources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetResources_604780(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604782 = path.getOrDefault("restapi_id")
  valid_604782 = validateParameter(valid_604782, JString, required = true,
                                 default = nil)
  if valid_604782 != nil:
    section.add "restapi_id", valid_604782
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_604783 = query.getOrDefault("embed")
  valid_604783 = validateParameter(valid_604783, JArray, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "embed", valid_604783
  var valid_604784 = query.getOrDefault("position")
  valid_604784 = validateParameter(valid_604784, JString, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "position", valid_604784
  var valid_604785 = query.getOrDefault("limit")
  valid_604785 = validateParameter(valid_604785, JInt, required = false, default = nil)
  if valid_604785 != nil:
    section.add "limit", valid_604785
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
  var valid_604786 = header.getOrDefault("X-Amz-Date")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-Date", valid_604786
  var valid_604787 = header.getOrDefault("X-Amz-Security-Token")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "X-Amz-Security-Token", valid_604787
  var valid_604788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604788 = validateParameter(valid_604788, JString, required = false,
                                 default = nil)
  if valid_604788 != nil:
    section.add "X-Amz-Content-Sha256", valid_604788
  var valid_604789 = header.getOrDefault("X-Amz-Algorithm")
  valid_604789 = validateParameter(valid_604789, JString, required = false,
                                 default = nil)
  if valid_604789 != nil:
    section.add "X-Amz-Algorithm", valid_604789
  var valid_604790 = header.getOrDefault("X-Amz-Signature")
  valid_604790 = validateParameter(valid_604790, JString, required = false,
                                 default = nil)
  if valid_604790 != nil:
    section.add "X-Amz-Signature", valid_604790
  var valid_604791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604791 = validateParameter(valid_604791, JString, required = false,
                                 default = nil)
  if valid_604791 != nil:
    section.add "X-Amz-SignedHeaders", valid_604791
  var valid_604792 = header.getOrDefault("X-Amz-Credential")
  valid_604792 = validateParameter(valid_604792, JString, required = false,
                                 default = nil)
  if valid_604792 != nil:
    section.add "X-Amz-Credential", valid_604792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604793: Call_GetResources_604779; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_604793.validator(path, query, header, formData, body)
  let scheme = call_604793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604793.url(scheme.get, call_604793.host, call_604793.base,
                         call_604793.route, valid.getOrDefault("path"))
  result = hook(call_604793, url, valid)

proc call*(call_604794: Call_GetResources_604779; restapiId: string;
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
  var path_604795 = newJObject()
  var query_604796 = newJObject()
  if embed != nil:
    query_604796.add "embed", embed
  add(query_604796, "position", newJString(position))
  add(query_604796, "limit", newJInt(limit))
  add(path_604795, "restapi_id", newJString(restapiId))
  result = call_604794.call(path_604795, query_604796, nil, nil, nil)

var getResources* = Call_GetResources_604779(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_604780,
    base: "/", url: url_GetResources_604781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_604797 = ref object of OpenApiRestCall_602417
proc url_GetSdk_604799(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetSdk_604798(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604800 = path.getOrDefault("sdk_type")
  valid_604800 = validateParameter(valid_604800, JString, required = true,
                                 default = nil)
  if valid_604800 != nil:
    section.add "sdk_type", valid_604800
  var valid_604801 = path.getOrDefault("stage_name")
  valid_604801 = validateParameter(valid_604801, JString, required = true,
                                 default = nil)
  if valid_604801 != nil:
    section.add "stage_name", valid_604801
  var valid_604802 = path.getOrDefault("restapi_id")
  valid_604802 = validateParameter(valid_604802, JString, required = true,
                                 default = nil)
  if valid_604802 != nil:
    section.add "restapi_id", valid_604802
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_604803 = query.getOrDefault("parameters.0.value")
  valid_604803 = validateParameter(valid_604803, JString, required = false,
                                 default = nil)
  if valid_604803 != nil:
    section.add "parameters.0.value", valid_604803
  var valid_604804 = query.getOrDefault("parameters.2.value")
  valid_604804 = validateParameter(valid_604804, JString, required = false,
                                 default = nil)
  if valid_604804 != nil:
    section.add "parameters.2.value", valid_604804
  var valid_604805 = query.getOrDefault("parameters.1.key")
  valid_604805 = validateParameter(valid_604805, JString, required = false,
                                 default = nil)
  if valid_604805 != nil:
    section.add "parameters.1.key", valid_604805
  var valid_604806 = query.getOrDefault("parameters.0.key")
  valid_604806 = validateParameter(valid_604806, JString, required = false,
                                 default = nil)
  if valid_604806 != nil:
    section.add "parameters.0.key", valid_604806
  var valid_604807 = query.getOrDefault("parameters.2.key")
  valid_604807 = validateParameter(valid_604807, JString, required = false,
                                 default = nil)
  if valid_604807 != nil:
    section.add "parameters.2.key", valid_604807
  var valid_604808 = query.getOrDefault("parameters.1.value")
  valid_604808 = validateParameter(valid_604808, JString, required = false,
                                 default = nil)
  if valid_604808 != nil:
    section.add "parameters.1.value", valid_604808
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
  var valid_604809 = header.getOrDefault("X-Amz-Date")
  valid_604809 = validateParameter(valid_604809, JString, required = false,
                                 default = nil)
  if valid_604809 != nil:
    section.add "X-Amz-Date", valid_604809
  var valid_604810 = header.getOrDefault("X-Amz-Security-Token")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Security-Token", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Content-Sha256", valid_604811
  var valid_604812 = header.getOrDefault("X-Amz-Algorithm")
  valid_604812 = validateParameter(valid_604812, JString, required = false,
                                 default = nil)
  if valid_604812 != nil:
    section.add "X-Amz-Algorithm", valid_604812
  var valid_604813 = header.getOrDefault("X-Amz-Signature")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-Signature", valid_604813
  var valid_604814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "X-Amz-SignedHeaders", valid_604814
  var valid_604815 = header.getOrDefault("X-Amz-Credential")
  valid_604815 = validateParameter(valid_604815, JString, required = false,
                                 default = nil)
  if valid_604815 != nil:
    section.add "X-Amz-Credential", valid_604815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604816: Call_GetSdk_604797; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_604816.validator(path, query, header, formData, body)
  let scheme = call_604816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604816.url(scheme.get, call_604816.host, call_604816.base,
                         call_604816.route, valid.getOrDefault("path"))
  result = hook(call_604816, url, valid)

proc call*(call_604817: Call_GetSdk_604797; sdkType: string; stageName: string;
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
  var path_604818 = newJObject()
  var query_604819 = newJObject()
  add(path_604818, "sdk_type", newJString(sdkType))
  add(query_604819, "parameters.0.value", newJString(parameters0Value))
  add(query_604819, "parameters.2.value", newJString(parameters2Value))
  add(query_604819, "parameters.1.key", newJString(parameters1Key))
  add(query_604819, "parameters.0.key", newJString(parameters0Key))
  add(query_604819, "parameters.2.key", newJString(parameters2Key))
  add(path_604818, "stage_name", newJString(stageName))
  add(query_604819, "parameters.1.value", newJString(parameters1Value))
  add(path_604818, "restapi_id", newJString(restapiId))
  result = call_604817.call(path_604818, query_604819, nil, nil, nil)

var getSdk* = Call_GetSdk_604797(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_604798, base: "/",
                              url: url_GetSdk_604799,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_604820 = ref object of OpenApiRestCall_602417
proc url_GetSdkType_604822(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "sdktype_id" in path, "`sdktype_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/sdktypes/"),
               (kind: VariableSegment, value: "sdktype_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetSdkType_604821(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_604823 = path.getOrDefault("sdktype_id")
  valid_604823 = validateParameter(valid_604823, JString, required = true,
                                 default = nil)
  if valid_604823 != nil:
    section.add "sdktype_id", valid_604823
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
  var valid_604824 = header.getOrDefault("X-Amz-Date")
  valid_604824 = validateParameter(valid_604824, JString, required = false,
                                 default = nil)
  if valid_604824 != nil:
    section.add "X-Amz-Date", valid_604824
  var valid_604825 = header.getOrDefault("X-Amz-Security-Token")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Security-Token", valid_604825
  var valid_604826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "X-Amz-Content-Sha256", valid_604826
  var valid_604827 = header.getOrDefault("X-Amz-Algorithm")
  valid_604827 = validateParameter(valid_604827, JString, required = false,
                                 default = nil)
  if valid_604827 != nil:
    section.add "X-Amz-Algorithm", valid_604827
  var valid_604828 = header.getOrDefault("X-Amz-Signature")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-Signature", valid_604828
  var valid_604829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604829 = validateParameter(valid_604829, JString, required = false,
                                 default = nil)
  if valid_604829 != nil:
    section.add "X-Amz-SignedHeaders", valid_604829
  var valid_604830 = header.getOrDefault("X-Amz-Credential")
  valid_604830 = validateParameter(valid_604830, JString, required = false,
                                 default = nil)
  if valid_604830 != nil:
    section.add "X-Amz-Credential", valid_604830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604831: Call_GetSdkType_604820; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604831.validator(path, query, header, formData, body)
  let scheme = call_604831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604831.url(scheme.get, call_604831.host, call_604831.base,
                         call_604831.route, valid.getOrDefault("path"))
  result = hook(call_604831, url, valid)

proc call*(call_604832: Call_GetSdkType_604820; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_604833 = newJObject()
  add(path_604833, "sdktype_id", newJString(sdktypeId))
  result = call_604832.call(path_604833, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_604820(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_604821,
                                      base: "/", url: url_GetSdkType_604822,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_604834 = ref object of OpenApiRestCall_602417
proc url_GetSdkTypes_604836(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSdkTypes_604835(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604837 = query.getOrDefault("position")
  valid_604837 = validateParameter(valid_604837, JString, required = false,
                                 default = nil)
  if valid_604837 != nil:
    section.add "position", valid_604837
  var valid_604838 = query.getOrDefault("limit")
  valid_604838 = validateParameter(valid_604838, JInt, required = false, default = nil)
  if valid_604838 != nil:
    section.add "limit", valid_604838
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
  var valid_604839 = header.getOrDefault("X-Amz-Date")
  valid_604839 = validateParameter(valid_604839, JString, required = false,
                                 default = nil)
  if valid_604839 != nil:
    section.add "X-Amz-Date", valid_604839
  var valid_604840 = header.getOrDefault("X-Amz-Security-Token")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Security-Token", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Content-Sha256", valid_604841
  var valid_604842 = header.getOrDefault("X-Amz-Algorithm")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-Algorithm", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Signature")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Signature", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-SignedHeaders", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Credential")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Credential", valid_604845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604846: Call_GetSdkTypes_604834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604846.validator(path, query, header, formData, body)
  let scheme = call_604846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604846.url(scheme.get, call_604846.host, call_604846.base,
                         call_604846.route, valid.getOrDefault("path"))
  result = hook(call_604846, url, valid)

proc call*(call_604847: Call_GetSdkTypes_604834; position: string = ""; limit: int = 0): Recallable =
  ## getSdkTypes
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_604848 = newJObject()
  add(query_604848, "position", newJString(position))
  add(query_604848, "limit", newJInt(limit))
  result = call_604847.call(nil, query_604848, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_604834(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_604835,
                                        base: "/", url: url_GetSdkTypes_604836,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604866 = ref object of OpenApiRestCall_602417
proc url_TagResource_604868(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_TagResource_604867(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604869 = path.getOrDefault("resource_arn")
  valid_604869 = validateParameter(valid_604869, JString, required = true,
                                 default = nil)
  if valid_604869 != nil:
    section.add "resource_arn", valid_604869
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
  var valid_604870 = header.getOrDefault("X-Amz-Date")
  valid_604870 = validateParameter(valid_604870, JString, required = false,
                                 default = nil)
  if valid_604870 != nil:
    section.add "X-Amz-Date", valid_604870
  var valid_604871 = header.getOrDefault("X-Amz-Security-Token")
  valid_604871 = validateParameter(valid_604871, JString, required = false,
                                 default = nil)
  if valid_604871 != nil:
    section.add "X-Amz-Security-Token", valid_604871
  var valid_604872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604872 = validateParameter(valid_604872, JString, required = false,
                                 default = nil)
  if valid_604872 != nil:
    section.add "X-Amz-Content-Sha256", valid_604872
  var valid_604873 = header.getOrDefault("X-Amz-Algorithm")
  valid_604873 = validateParameter(valid_604873, JString, required = false,
                                 default = nil)
  if valid_604873 != nil:
    section.add "X-Amz-Algorithm", valid_604873
  var valid_604874 = header.getOrDefault("X-Amz-Signature")
  valid_604874 = validateParameter(valid_604874, JString, required = false,
                                 default = nil)
  if valid_604874 != nil:
    section.add "X-Amz-Signature", valid_604874
  var valid_604875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604875 = validateParameter(valid_604875, JString, required = false,
                                 default = nil)
  if valid_604875 != nil:
    section.add "X-Amz-SignedHeaders", valid_604875
  var valid_604876 = header.getOrDefault("X-Amz-Credential")
  valid_604876 = validateParameter(valid_604876, JString, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "X-Amz-Credential", valid_604876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604878: Call_TagResource_604866; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_604878.validator(path, query, header, formData, body)
  let scheme = call_604878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604878.url(scheme.get, call_604878.host, call_604878.base,
                         call_604878.route, valid.getOrDefault("path"))
  result = hook(call_604878, url, valid)

proc call*(call_604879: Call_TagResource_604866; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_604880 = newJObject()
  var body_604881 = newJObject()
  add(path_604880, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_604881 = body
  result = call_604879.call(path_604880, nil, nil, nil, body_604881)

var tagResource* = Call_TagResource_604866(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_604867,
                                        base: "/", url: url_TagResource_604868,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_604849 = ref object of OpenApiRestCall_602417
proc url_GetTags_604851(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetTags_604850(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604852 = path.getOrDefault("resource_arn")
  valid_604852 = validateParameter(valid_604852, JString, required = true,
                                 default = nil)
  if valid_604852 != nil:
    section.add "resource_arn", valid_604852
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_604853 = query.getOrDefault("position")
  valid_604853 = validateParameter(valid_604853, JString, required = false,
                                 default = nil)
  if valid_604853 != nil:
    section.add "position", valid_604853
  var valid_604854 = query.getOrDefault("limit")
  valid_604854 = validateParameter(valid_604854, JInt, required = false, default = nil)
  if valid_604854 != nil:
    section.add "limit", valid_604854
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
  var valid_604855 = header.getOrDefault("X-Amz-Date")
  valid_604855 = validateParameter(valid_604855, JString, required = false,
                                 default = nil)
  if valid_604855 != nil:
    section.add "X-Amz-Date", valid_604855
  var valid_604856 = header.getOrDefault("X-Amz-Security-Token")
  valid_604856 = validateParameter(valid_604856, JString, required = false,
                                 default = nil)
  if valid_604856 != nil:
    section.add "X-Amz-Security-Token", valid_604856
  var valid_604857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "X-Amz-Content-Sha256", valid_604857
  var valid_604858 = header.getOrDefault("X-Amz-Algorithm")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Algorithm", valid_604858
  var valid_604859 = header.getOrDefault("X-Amz-Signature")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Signature", valid_604859
  var valid_604860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604860 = validateParameter(valid_604860, JString, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "X-Amz-SignedHeaders", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-Credential")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-Credential", valid_604861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604862: Call_GetTags_604849; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_604862.validator(path, query, header, formData, body)
  let scheme = call_604862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604862.url(scheme.get, call_604862.host, call_604862.base,
                         call_604862.route, valid.getOrDefault("path"))
  result = hook(call_604862, url, valid)

proc call*(call_604863: Call_GetTags_604849; resourceArn: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_604864 = newJObject()
  var query_604865 = newJObject()
  add(path_604864, "resource_arn", newJString(resourceArn))
  add(query_604865, "position", newJString(position))
  add(query_604865, "limit", newJInt(limit))
  result = call_604863.call(path_604864, query_604865, nil, nil, nil)

var getTags* = Call_GetTags_604849(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_604850, base: "/",
                                url: url_GetTags_604851,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_604882 = ref object of OpenApiRestCall_602417
proc url_GetUsage_604884(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId"),
               (kind: ConstantSegment, value: "/usage#startDate&endDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUsage_604883(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604885 = path.getOrDefault("usageplanId")
  valid_604885 = validateParameter(valid_604885, JString, required = true,
                                 default = nil)
  if valid_604885 != nil:
    section.add "usageplanId", valid_604885
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
  var valid_604886 = query.getOrDefault("endDate")
  valid_604886 = validateParameter(valid_604886, JString, required = true,
                                 default = nil)
  if valid_604886 != nil:
    section.add "endDate", valid_604886
  var valid_604887 = query.getOrDefault("startDate")
  valid_604887 = validateParameter(valid_604887, JString, required = true,
                                 default = nil)
  if valid_604887 != nil:
    section.add "startDate", valid_604887
  var valid_604888 = query.getOrDefault("keyId")
  valid_604888 = validateParameter(valid_604888, JString, required = false,
                                 default = nil)
  if valid_604888 != nil:
    section.add "keyId", valid_604888
  var valid_604889 = query.getOrDefault("position")
  valid_604889 = validateParameter(valid_604889, JString, required = false,
                                 default = nil)
  if valid_604889 != nil:
    section.add "position", valid_604889
  var valid_604890 = query.getOrDefault("limit")
  valid_604890 = validateParameter(valid_604890, JInt, required = false, default = nil)
  if valid_604890 != nil:
    section.add "limit", valid_604890
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
  var valid_604891 = header.getOrDefault("X-Amz-Date")
  valid_604891 = validateParameter(valid_604891, JString, required = false,
                                 default = nil)
  if valid_604891 != nil:
    section.add "X-Amz-Date", valid_604891
  var valid_604892 = header.getOrDefault("X-Amz-Security-Token")
  valid_604892 = validateParameter(valid_604892, JString, required = false,
                                 default = nil)
  if valid_604892 != nil:
    section.add "X-Amz-Security-Token", valid_604892
  var valid_604893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604893 = validateParameter(valid_604893, JString, required = false,
                                 default = nil)
  if valid_604893 != nil:
    section.add "X-Amz-Content-Sha256", valid_604893
  var valid_604894 = header.getOrDefault("X-Amz-Algorithm")
  valid_604894 = validateParameter(valid_604894, JString, required = false,
                                 default = nil)
  if valid_604894 != nil:
    section.add "X-Amz-Algorithm", valid_604894
  var valid_604895 = header.getOrDefault("X-Amz-Signature")
  valid_604895 = validateParameter(valid_604895, JString, required = false,
                                 default = nil)
  if valid_604895 != nil:
    section.add "X-Amz-Signature", valid_604895
  var valid_604896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604896 = validateParameter(valid_604896, JString, required = false,
                                 default = nil)
  if valid_604896 != nil:
    section.add "X-Amz-SignedHeaders", valid_604896
  var valid_604897 = header.getOrDefault("X-Amz-Credential")
  valid_604897 = validateParameter(valid_604897, JString, required = false,
                                 default = nil)
  if valid_604897 != nil:
    section.add "X-Amz-Credential", valid_604897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604898: Call_GetUsage_604882; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_604898.validator(path, query, header, formData, body)
  let scheme = call_604898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604898.url(scheme.get, call_604898.host, call_604898.base,
                         call_604898.route, valid.getOrDefault("path"))
  result = hook(call_604898, url, valid)

proc call*(call_604899: Call_GetUsage_604882; endDate: string; startDate: string;
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
  var path_604900 = newJObject()
  var query_604901 = newJObject()
  add(query_604901, "endDate", newJString(endDate))
  add(query_604901, "startDate", newJString(startDate))
  add(path_604900, "usageplanId", newJString(usageplanId))
  add(query_604901, "keyId", newJString(keyId))
  add(query_604901, "position", newJString(position))
  add(query_604901, "limit", newJInt(limit))
  result = call_604899.call(path_604900, query_604901, nil, nil, nil)

var getUsage* = Call_GetUsage_604882(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_604883, base: "/",
                                  url: url_GetUsage_604884,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_604902 = ref object of OpenApiRestCall_602417
proc url_ImportApiKeys_604904(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportApiKeys_604903(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604905 = query.getOrDefault("mode")
  valid_604905 = validateParameter(valid_604905, JString, required = true,
                                 default = newJString("import"))
  if valid_604905 != nil:
    section.add "mode", valid_604905
  var valid_604906 = query.getOrDefault("failonwarnings")
  valid_604906 = validateParameter(valid_604906, JBool, required = false, default = nil)
  if valid_604906 != nil:
    section.add "failonwarnings", valid_604906
  var valid_604907 = query.getOrDefault("format")
  valid_604907 = validateParameter(valid_604907, JString, required = true,
                                 default = newJString("csv"))
  if valid_604907 != nil:
    section.add "format", valid_604907
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
  var valid_604908 = header.getOrDefault("X-Amz-Date")
  valid_604908 = validateParameter(valid_604908, JString, required = false,
                                 default = nil)
  if valid_604908 != nil:
    section.add "X-Amz-Date", valid_604908
  var valid_604909 = header.getOrDefault("X-Amz-Security-Token")
  valid_604909 = validateParameter(valid_604909, JString, required = false,
                                 default = nil)
  if valid_604909 != nil:
    section.add "X-Amz-Security-Token", valid_604909
  var valid_604910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604910 = validateParameter(valid_604910, JString, required = false,
                                 default = nil)
  if valid_604910 != nil:
    section.add "X-Amz-Content-Sha256", valid_604910
  var valid_604911 = header.getOrDefault("X-Amz-Algorithm")
  valid_604911 = validateParameter(valid_604911, JString, required = false,
                                 default = nil)
  if valid_604911 != nil:
    section.add "X-Amz-Algorithm", valid_604911
  var valid_604912 = header.getOrDefault("X-Amz-Signature")
  valid_604912 = validateParameter(valid_604912, JString, required = false,
                                 default = nil)
  if valid_604912 != nil:
    section.add "X-Amz-Signature", valid_604912
  var valid_604913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604913 = validateParameter(valid_604913, JString, required = false,
                                 default = nil)
  if valid_604913 != nil:
    section.add "X-Amz-SignedHeaders", valid_604913
  var valid_604914 = header.getOrDefault("X-Amz-Credential")
  valid_604914 = validateParameter(valid_604914, JString, required = false,
                                 default = nil)
  if valid_604914 != nil:
    section.add "X-Amz-Credential", valid_604914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604916: Call_ImportApiKeys_604902; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_604916.validator(path, query, header, formData, body)
  let scheme = call_604916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604916.url(scheme.get, call_604916.host, call_604916.base,
                         call_604916.route, valid.getOrDefault("path"))
  result = hook(call_604916, url, valid)

proc call*(call_604917: Call_ImportApiKeys_604902; body: JsonNode;
          mode: string = "import"; failonwarnings: bool = false; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   mode: string (required)
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_604918 = newJObject()
  var body_604919 = newJObject()
  add(query_604918, "mode", newJString(mode))
  add(query_604918, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_604919 = body
  add(query_604918, "format", newJString(format))
  result = call_604917.call(nil, query_604918, nil, nil, body_604919)

var importApiKeys* = Call_ImportApiKeys_604902(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_604903,
    base: "/", url: url_ImportApiKeys_604904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_604920 = ref object of OpenApiRestCall_602417
proc url_ImportRestApi_604922(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportRestApi_604921(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604923 = query.getOrDefault("parameters.0.value")
  valid_604923 = validateParameter(valid_604923, JString, required = false,
                                 default = nil)
  if valid_604923 != nil:
    section.add "parameters.0.value", valid_604923
  var valid_604924 = query.getOrDefault("parameters.2.value")
  valid_604924 = validateParameter(valid_604924, JString, required = false,
                                 default = nil)
  if valid_604924 != nil:
    section.add "parameters.2.value", valid_604924
  var valid_604925 = query.getOrDefault("parameters.1.key")
  valid_604925 = validateParameter(valid_604925, JString, required = false,
                                 default = nil)
  if valid_604925 != nil:
    section.add "parameters.1.key", valid_604925
  var valid_604926 = query.getOrDefault("parameters.0.key")
  valid_604926 = validateParameter(valid_604926, JString, required = false,
                                 default = nil)
  if valid_604926 != nil:
    section.add "parameters.0.key", valid_604926
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_604927 = query.getOrDefault("mode")
  valid_604927 = validateParameter(valid_604927, JString, required = true,
                                 default = newJString("import"))
  if valid_604927 != nil:
    section.add "mode", valid_604927
  var valid_604928 = query.getOrDefault("parameters.2.key")
  valid_604928 = validateParameter(valid_604928, JString, required = false,
                                 default = nil)
  if valid_604928 != nil:
    section.add "parameters.2.key", valid_604928
  var valid_604929 = query.getOrDefault("failonwarnings")
  valid_604929 = validateParameter(valid_604929, JBool, required = false, default = nil)
  if valid_604929 != nil:
    section.add "failonwarnings", valid_604929
  var valid_604930 = query.getOrDefault("parameters.1.value")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "parameters.1.value", valid_604930
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
  var valid_604931 = header.getOrDefault("X-Amz-Date")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-Date", valid_604931
  var valid_604932 = header.getOrDefault("X-Amz-Security-Token")
  valid_604932 = validateParameter(valid_604932, JString, required = false,
                                 default = nil)
  if valid_604932 != nil:
    section.add "X-Amz-Security-Token", valid_604932
  var valid_604933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604933 = validateParameter(valid_604933, JString, required = false,
                                 default = nil)
  if valid_604933 != nil:
    section.add "X-Amz-Content-Sha256", valid_604933
  var valid_604934 = header.getOrDefault("X-Amz-Algorithm")
  valid_604934 = validateParameter(valid_604934, JString, required = false,
                                 default = nil)
  if valid_604934 != nil:
    section.add "X-Amz-Algorithm", valid_604934
  var valid_604935 = header.getOrDefault("X-Amz-Signature")
  valid_604935 = validateParameter(valid_604935, JString, required = false,
                                 default = nil)
  if valid_604935 != nil:
    section.add "X-Amz-Signature", valid_604935
  var valid_604936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604936 = validateParameter(valid_604936, JString, required = false,
                                 default = nil)
  if valid_604936 != nil:
    section.add "X-Amz-SignedHeaders", valid_604936
  var valid_604937 = header.getOrDefault("X-Amz-Credential")
  valid_604937 = validateParameter(valid_604937, JString, required = false,
                                 default = nil)
  if valid_604937 != nil:
    section.add "X-Amz-Credential", valid_604937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604939: Call_ImportRestApi_604920; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_604939.validator(path, query, header, formData, body)
  let scheme = call_604939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604939.url(scheme.get, call_604939.host, call_604939.base,
                         call_604939.route, valid.getOrDefault("path"))
  result = hook(call_604939, url, valid)

proc call*(call_604940: Call_ImportRestApi_604920; body: JsonNode;
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
  var query_604941 = newJObject()
  var body_604942 = newJObject()
  add(query_604941, "parameters.0.value", newJString(parameters0Value))
  add(query_604941, "parameters.2.value", newJString(parameters2Value))
  add(query_604941, "parameters.1.key", newJString(parameters1Key))
  add(query_604941, "parameters.0.key", newJString(parameters0Key))
  add(query_604941, "mode", newJString(mode))
  add(query_604941, "parameters.2.key", newJString(parameters2Key))
  add(query_604941, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_604942 = body
  add(query_604941, "parameters.1.value", newJString(parameters1Value))
  result = call_604940.call(nil, query_604941, nil, nil, body_604942)

var importRestApi* = Call_ImportRestApi_604920(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_604921,
    base: "/", url: url_ImportRestApi_604922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604943 = ref object of OpenApiRestCall_602417
proc url_UntagResource_604945(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UntagResource_604944(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604946 = path.getOrDefault("resource_arn")
  valid_604946 = validateParameter(valid_604946, JString, required = true,
                                 default = nil)
  if valid_604946 != nil:
    section.add "resource_arn", valid_604946
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_604947 = query.getOrDefault("tagKeys")
  valid_604947 = validateParameter(valid_604947, JArray, required = true, default = nil)
  if valid_604947 != nil:
    section.add "tagKeys", valid_604947
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
  var valid_604948 = header.getOrDefault("X-Amz-Date")
  valid_604948 = validateParameter(valid_604948, JString, required = false,
                                 default = nil)
  if valid_604948 != nil:
    section.add "X-Amz-Date", valid_604948
  var valid_604949 = header.getOrDefault("X-Amz-Security-Token")
  valid_604949 = validateParameter(valid_604949, JString, required = false,
                                 default = nil)
  if valid_604949 != nil:
    section.add "X-Amz-Security-Token", valid_604949
  var valid_604950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604950 = validateParameter(valid_604950, JString, required = false,
                                 default = nil)
  if valid_604950 != nil:
    section.add "X-Amz-Content-Sha256", valid_604950
  var valid_604951 = header.getOrDefault("X-Amz-Algorithm")
  valid_604951 = validateParameter(valid_604951, JString, required = false,
                                 default = nil)
  if valid_604951 != nil:
    section.add "X-Amz-Algorithm", valid_604951
  var valid_604952 = header.getOrDefault("X-Amz-Signature")
  valid_604952 = validateParameter(valid_604952, JString, required = false,
                                 default = nil)
  if valid_604952 != nil:
    section.add "X-Amz-Signature", valid_604952
  var valid_604953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604953 = validateParameter(valid_604953, JString, required = false,
                                 default = nil)
  if valid_604953 != nil:
    section.add "X-Amz-SignedHeaders", valid_604953
  var valid_604954 = header.getOrDefault("X-Amz-Credential")
  valid_604954 = validateParameter(valid_604954, JString, required = false,
                                 default = nil)
  if valid_604954 != nil:
    section.add "X-Amz-Credential", valid_604954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604955: Call_UntagResource_604943; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_604955.validator(path, query, header, formData, body)
  let scheme = call_604955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604955.url(scheme.get, call_604955.host, call_604955.base,
                         call_604955.route, valid.getOrDefault("path"))
  result = hook(call_604955, url, valid)

proc call*(call_604956: Call_UntagResource_604943; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_604957 = newJObject()
  var query_604958 = newJObject()
  add(path_604957, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_604958.add "tagKeys", tagKeys
  result = call_604956.call(path_604957, query_604958, nil, nil, nil)

var untagResource* = Call_UntagResource_604943(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_604944,
    base: "/", url: url_UntagResource_604945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_604959 = ref object of OpenApiRestCall_602417
proc url_UpdateUsage_604961(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateUsage_604960(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604962 = path.getOrDefault("keyId")
  valid_604962 = validateParameter(valid_604962, JString, required = true,
                                 default = nil)
  if valid_604962 != nil:
    section.add "keyId", valid_604962
  var valid_604963 = path.getOrDefault("usageplanId")
  valid_604963 = validateParameter(valid_604963, JString, required = true,
                                 default = nil)
  if valid_604963 != nil:
    section.add "usageplanId", valid_604963
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
  var valid_604964 = header.getOrDefault("X-Amz-Date")
  valid_604964 = validateParameter(valid_604964, JString, required = false,
                                 default = nil)
  if valid_604964 != nil:
    section.add "X-Amz-Date", valid_604964
  var valid_604965 = header.getOrDefault("X-Amz-Security-Token")
  valid_604965 = validateParameter(valid_604965, JString, required = false,
                                 default = nil)
  if valid_604965 != nil:
    section.add "X-Amz-Security-Token", valid_604965
  var valid_604966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604966 = validateParameter(valid_604966, JString, required = false,
                                 default = nil)
  if valid_604966 != nil:
    section.add "X-Amz-Content-Sha256", valid_604966
  var valid_604967 = header.getOrDefault("X-Amz-Algorithm")
  valid_604967 = validateParameter(valid_604967, JString, required = false,
                                 default = nil)
  if valid_604967 != nil:
    section.add "X-Amz-Algorithm", valid_604967
  var valid_604968 = header.getOrDefault("X-Amz-Signature")
  valid_604968 = validateParameter(valid_604968, JString, required = false,
                                 default = nil)
  if valid_604968 != nil:
    section.add "X-Amz-Signature", valid_604968
  var valid_604969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604969 = validateParameter(valid_604969, JString, required = false,
                                 default = nil)
  if valid_604969 != nil:
    section.add "X-Amz-SignedHeaders", valid_604969
  var valid_604970 = header.getOrDefault("X-Amz-Credential")
  valid_604970 = validateParameter(valid_604970, JString, required = false,
                                 default = nil)
  if valid_604970 != nil:
    section.add "X-Amz-Credential", valid_604970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604972: Call_UpdateUsage_604959; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_604972.validator(path, query, header, formData, body)
  let scheme = call_604972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604972.url(scheme.get, call_604972.host, call_604972.base,
                         call_604972.route, valid.getOrDefault("path"))
  result = hook(call_604972, url, valid)

proc call*(call_604973: Call_UpdateUsage_604959; keyId: string; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   body: JObject (required)
  var path_604974 = newJObject()
  var body_604975 = newJObject()
  add(path_604974, "keyId", newJString(keyId))
  add(path_604974, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_604975 = body
  result = call_604973.call(path_604974, nil, nil, nil, body_604975)

var updateUsage* = Call_UpdateUsage_604959(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_604960,
                                        base: "/", url: url_UpdateUsage_604961,
                                        schemes: {Scheme.Https, Scheme.Http})
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
